import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/record/record_modal.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/utils/recording_export.dart';

class ConvertRecording extends StatelessWidget {
  const ConvertRecording({super.key});

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
                return errorDialog(
                  context,
                  "${appLocalizations.convertRecording}: $e",
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(ExportFormat.csv),
                  child: const Text("CSV"),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(ExportFormat.kml),
                  child: const Text("KML"),
                ),
              ],
            );
          },
        );

        if (format == null) return;

        final String baseName = recordingFile.name.replaceAll(
          RegExp(r"\.nmr$", caseSensitive: false),
          "",
        );

        final String content = format == ExportFormat.kml
            ? recordedDataToKml(recordedData)
            : recordedDataToCsv(recordedData);

        final String ext = format.name.toLowerCase();

        final XTypeGroup group = XTypeGroup(label: ext, extensions: [ext]);
        final FileSaveLocation? saveLocation = await getSaveLocation(
          suggestedName: "$baseName.$ext",
          acceptedTypeGroups: [group],
        );

        if (saveLocation == null) return;

        final XFile outFile = XFile.fromData(
          Uint8List.fromList(utf8.encode(content)),
          mimeType: format == ExportFormat.kml
              ? "application/vnd.google-earth.kml+xml"
              : "text/csv",
          name: "$baseName.$ext",
        );
        await outFile.saveTo(saveLocation.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.exportFormatSaved(saveLocation.path),
              ),
            ),
          );
        }
      },
    );
  }
}
