import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/types/recording/recorded_data.dart';

Widget recordModal(
  BuildContext context,
  MethodChannel platform,
  Function(RecordedData) onDataLoaded,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.fiber_smart_record_outlined),
          title: const Text("New recording"),
          subtitle: const Text(
            "You will be taken to the recording setup dialog.",
          ),
          onTap: () async => (),
        ),
        ListTile(
          leading: const Icon(Icons.replay_outlined),
          title: const Text("Replay recording"),
          subtitle: const Text(
            "You will be asked to select a valid .nmr (NetManager Recording) file.",
          ),
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
              //todo
            }
          },
        ),
      ],
    ),
  );
}
