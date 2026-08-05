import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/format_utils.dart';
import 'package:netmanager/utils/database_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManagerDialog extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final List<String> importedDatabases;
  final VoidCallback onUpdate;

  const DatabaseManagerDialog({
    super.key,
    required this.sharedPreferences,
    required this.importedDatabases,
    required this.onUpdate,
  });

  Future<void> _handleImport(
    BuildContext context,
    StateSetter setDialogState,
    AppLocalizations appLocalizations,
  ) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: "Cell Databases",
      extensions: ["clf", "ntm"],
    );

    final XFile? selectedFile = await openFile(acceptedTypeGroups: [typeGroup]);
    if (selectedFile == null) return;

    final String extension = selectedFile.name.split(".").last.toLowerCase();
    final bool isClf = extension == "clf";

    final String? firstLinePlmn = await extractPlmnFromFirstLine(
      selectedFile.path,
      isClf,
    );

    if (firstLinePlmn == null || firstLinePlmn.trim().isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) =>
            ErrorDialog(e: appLocalizations.noValidPlmnInDatabase),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(appLocalizations.convertingCells)),
          ],
        ),
      ),
    );

    try {
      final db = await CellDatabase.getDatabase();
      final file = File(selectedFile.path);

      final Stream<String> lines;

      try {
        lines = file
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter());
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialog(e: "${appLocalizations.importDatabase} $e");
            },
          );
        }

        return;
      }

      int operationsCounter = 0;
      Batch batch = db.batch();

      final Set<String> localImportedPlmns = {};

      await for (final line in lines) {
        if (line.trim().isEmpty || line.startsWith("#")) continue;
        final parts = decodeRow(line, ";");

        try {
          String currentPlmn = "";
          if (isClf) {
            if (parts.isNotEmpty && parts[0].length >= 5) {
              currentPlmn = parts[0];
            } else {
              continue;
            }
          } else {
            if (parts.length >= 3) {
              currentPlmn = "${parts[1]}${parts[2]}";
            } else {
              continue;
            }
          }

          if (currentPlmn.trim().isEmpty) continue;
          localImportedPlmns.add(currentPlmn);

          int networkGen = -1;
          int cid = -1;
          double latitude = 0.0;
          double longitude = 0.0;
          String description = "";
          int? channelNumber;

          if (isClf) {
            if (parts.length < 9) continue;

            final sys = int.tryParse(parts[8]) ?? 0;
            if (sys == 1) networkGen = 2;
            if (sys == 3) networkGen = 3;
            if (sys == 4) networkGen = 4;
            if (sys == 5) networkGen = 5;

            cid = int.parse(parts[1]);
            latitude = double.parse(parts[4]);
            longitude = double.parse(parts[5]);
            description = parts[7].isNotEmpty
                ? parts[7]
                : (parts.length > 9 ? parts[9] : "");
            channelNumber = null;
          } else {
            if (parts.length < 10) continue;

            final String type = parts[0].toUpperCase();
            if (type == "2G") {
              networkGen = 2;
            } else if (type == "3G") {
              networkGen = 3;
            } else if (type == "4G") {
              networkGen = 4;
            } else if (type == "5G") {
              networkGen = 5;
            }

            latitude = double.parse(parts[7]);
            longitude = double.parse(parts[8]);
            description = parts[9];
            channelNumber = parts.length > 10 ? int.tryParse(parts[10]) : null;

            if (type == "4G") {
              final int tempCi = int.parse(parts[3]);
              final int eNb = int.parse(parts[5]);
              cid = (eNb * 256) + tempCi;
            } else {
              cid = int.parse(parts[3]);
            }
          }

          batch.insert("cells", {
            "networkgen": networkGen,
            "plmn": currentPlmn,
            "cid": cid,
            "latitude": latitude,
            "longitude": longitude,
            "description": description,
            "channelnumber": channelNumber,
          });

          operationsCounter++;

          if (operationsCounter % 5000 == 0) {
            await batch.commit(noResult: true);
            batch = db.batch();
          }
        } catch (_) {
          continue;
        }
      }

      await batch.commit(noResult: true);

      bool updated = false;
      for (final foundPlmn in localImportedPlmns) {
        final String destinationFileName = "$foundPlmn.$extension";
        if (!importedDatabases.contains(destinationFileName)) {
          importedDatabases.add(destinationFileName);
          updated = true;
        }
      }

      if (updated) {
        await sharedPreferences.setStringList(
          "importedDatabases",
          importedDatabases,
        );

        setDialogState(() {});
        onUpdate();
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              ErrorDialog(e: "${appLocalizations.databaseIndexing}: $e"),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleRemove(
    String dbFileName,
    StateSetter setDialogState,
  ) async {
    final String plmn = dbFileName.split(".").first;
    final db = await CellDatabase.getDatabase();

    await db.delete("cells", where: "plmn = ?", whereArgs: [plmn]);

    importedDatabases.remove(dbFileName);
    await sharedPreferences.setStringList(
      "importedDatabases",
      importedDatabases,
    );

    setDialogState(() {});
    onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(appLocalizations.manageDatabases),
          content: SizedBox(
            width: double.maxFinite,
            child: importedDatabases.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      appLocalizations.noImportedDatabases,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: importedDatabases.length,
                    itemBuilder: (context, index) {
                      final String dbName = importedDatabases[index];
                      final parts = dbName.split(".");
                      final String plmnLabel = parts.first;
                      final String formatType = parts.last.toUpperCase();

                      return ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: Text(plmnLabel),
                        subtitle: Text(
                          appLocalizations.databaseFormat(formatType),
                        ),
                        trailing: IconButton(
                          tooltip: appLocalizations.deleteDatabase,
                          icon: const Icon(Icons.delete_outlined),
                          onPressed: () async {
                            await _handleRemove(dbName, setDialogState);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appLocalizations.close),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _handleImport(context, setDialogState, appLocalizations);
              },
              icon: const Icon(Icons.file_download_outlined),
              label: Text(appLocalizations.import),
            ),
          ],
        );
      },
    );
  }
}
