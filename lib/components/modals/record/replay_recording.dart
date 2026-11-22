import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/types/storage/storage_file.dart';
import 'package:netmanager/utils/storage_utils.dart';

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
        StorageFile? recordingFile;

        try {
          recordingFile = await StorageUtils.pickFile(["nmr"]);
          if (recordingFile == null) return;

          String content = await File(recordingFile.path).readAsString();
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
        } finally {
          if (recordingFile != null) {
            try {
              await StorageUtils.deleteCachedFile(recordingFile.path);
            } catch (_) {}
          }
        }
      },
    );
  }
}
