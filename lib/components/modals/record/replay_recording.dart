import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/recording/recorded_data.dart';

class ReplayRecording extends StatelessWidget {
  const ReplayRecording({super.key, required this.onDataLoaded});

  final void Function(RecordedData) onDataLoaded;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.replay_outlined),
      title: Text(appLocalizations.replayRecording),
      subtitle: Text(appLocalizations.selectRecording),
      onTap: () async {
        const XTypeGroup typeGroup = XTypeGroup(
          label: "NetManager Recording",
          extensions: ["nmr"],
        );

        final XFile? recordingFile = await openFile(
          acceptedTypeGroups: [typeGroup],
        );
        if (recordingFile == null) return;

        try {
          String content = await recordingFile.readAsString();
          final Map<String, dynamic> jsonData = json.decode(content);
          final recordedData = RecordedData.fromJson(jsonData);

          onDataLoaded(recordedData);

          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(
                  e: "${appLocalizations.replayRecording}: $e",
                );
              },
            );
          }

          return;
        }
      },
    );
  }
}
