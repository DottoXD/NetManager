import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/dialogs/cell_editor.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/storage/storage_file.dart';
import 'package:netmanager/utils/cell_import_worker.dart';
import 'package:netmanager/utils/database_utils.dart';
import 'package:netmanager/utils/storage_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    StorageFile? selectedFile;

    try {
      selectedFile = await StorageUtils.pickFile(["clf", "ntm"]);
    } catch (e) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => ErrorDialog(e: e),
        );
      }

      return;
    }

    if (selectedFile == null) return;
    if (!context.mounted) {
      await StorageUtils.deleteCachedFile(selectedFile.path);
      return;
    }

    try {
      final String extension = selectedFile.name.split(".").last.toLowerCase();
      final bool isClf = extension == "clf";

      String? firstLinePlmn;
      try {
        firstLinePlmn = await extractPlmnFromFirstLine(
          selectedFile.path,
          isClf,
        );
      } catch (_) {
        firstLinePlmn = null;
      }

      if (!context.mounted) return;
      if (firstLinePlmn == null || firstLinePlmn.trim().isEmpty) {
        await showDialog(
          context: context,
          builder: (context) =>
              ErrorDialog(e: appLocalizations.noValidPlmnInDatabase),
        );
        return;
      }

      final ValueNotifier<int> convertedCount = ValueNotifier(0);
      Object? importError;
      bool completed = false;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: convertedCount,
                    builder: (context, count, child) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appLocalizations.convertingCells),
                        const SizedBox(height: 4),
                        Text(appLocalizations.convertedCellsCount(count)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        final db = await CellDatabase.getDatabase();
        final CellImportResult result = await importCellFile(
          database: db,
          path: selectedFile.path,
          isClf: isClf,
          onProgress: (count) => convertedCount.value = count,
        );

        if (result.importedPlmns.isEmpty) {
          throw FormatException(appLocalizations.noValidPlmnInDatabase);
        }

        bool updated = false;
        for (final foundPlmn in result.importedPlmns) {
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
        }
        completed = true;
      } catch (e) {
        importError = e;
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        convertedCount.dispose();
      }

      if (!context.mounted) return;
      if (importError != null) {
        await showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            e: "${appLocalizations.databaseIndexing}: $importError",
          ),
        );
      } else if (completed) {
        setDialogState(() {});
        onUpdate();
      }
    } finally {
      try {
        await StorageUtils.deleteCachedFile(selectedFile.path);
      } catch (_) {}
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
          icon: const Icon(Icons.dataset_outlined),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: appLocalizations.editDatabase,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      CellEditorDialog(plmn: plmnLabel),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: appLocalizations.deleteDatabase,
                              icon: const Icon(Icons.delete_outlined),
                              onPressed: () async {
                                await _handleRemove(dbName, setDialogState);
                              },
                            ),
                          ],
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
