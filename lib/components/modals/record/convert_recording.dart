import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/record/record_modal.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/utils/recording_export.dart';
import 'package:path_provider/path_provider.dart';

class ConvertRecording extends StatelessWidget {
  const ConvertRecording({super.key, required this.platform});

  final MethodChannel platform;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.replay_outlined),
      title: Text(appLocalizations.convertRecording),
      subtitle: Text(appLocalizations.conversionDescription),
      onTap: () async {
        const XTypeGroup typeGroup = XTypeGroup(
          label: "NetManager Recording",
          extensions: ["nmr"],
        );

        final XFile? recordingFile = await openFile(
          acceptedTypeGroups: [typeGroup],
        );
        if (recordingFile == null) return;

        RecordedData recordedData;
        try {
          final String content = await recordingFile.readAsString();
          final Map<String, dynamic> jsonData = json.decode(content);
          recordedData = RecordedData.fromJson(jsonData);
        } catch (e) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(
                  e: "${appLocalizations.convertRecording}: $e",
                );
              },
            );
          }
          return;
        }

        if (!context.mounted) return;

        final ExportFormat? format = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(appLocalizations.exportFormatTitle),
              content: Text(appLocalizations.exportFormatDescription),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(appLocalizations.cancel),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(ExportFormat.csv),
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text("CSV"),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(ExportFormat.kml),
                  icon: const Icon(Icons.landscape_outlined),
                  label: const Text("KML"),
                ),
              ],
            );
          },
        );

        if (format == null) return;

        final String baseName = recordingFile.name
            .replaceAll(RegExp(r"\.nmr$", caseSensitive: false), "")
            .replaceAll(RegExp(r"\.bin$", caseSensitive: false), "");

        final String ext = format.name.toLowerCase();

        try {
          final String content = format == ExportFormat.kml
              ? recordedDataToKml(recordedData)
              : recordedDataToCsv(recordedData);

          final dir = await getTemporaryDirectory();
          final exportFolder = Directory("${dir.path}/exports");
          if (!exportFolder.existsSync()) {
            await exportFolder.create();
          }

          final savePath = "${exportFolder.path}/$baseName.$ext";

          final File outFile = File(savePath);
          await outFile.writeAsString(content);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appLocalizations.exportFormatSaved(savePath)),
              ),
            );
          }

          await platform.invokeMethod("share", {"path": savePath});
        } catch (e) {
          if (context.mounted) {
            await platform.invokeMethod<bool>("showToast", {
              "message": AppLocalizations.of(context)!.unexpectedError,
            });
          }
        }
      },
    );
  }
}
