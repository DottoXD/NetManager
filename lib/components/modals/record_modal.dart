import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/types/recording/recorded_data.dart';

Widget recordModal(
  BuildContext context,
  MethodChannel platform,
  ValueNotifier<bool> recordingActionNotifier,
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
          onTap: () async {
            final TextEditingController nameController = TextEditingController(
              text: "NetManager_${DateTime.now().millisecondsSinceEpoch}",
            );
            final TextEditingController intervalController =
                TextEditingController(text: "10");
            final ValueNotifier<String?> directoryPathNotifier = ValueNotifier(
              null,
            );

            final bool? start = await showDialog(
              context: context,
              builder: (BuildContext context) {
                // todo: add usable toggle for the 'usable' tracker
                return AlertDialog(
                  title: const Text("New recording"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "File name",
                            suffixText: ".nmr",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: intervalController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: "Interval between recordings",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<String?>(
                          valueListenable: directoryPathNotifier,
                          builder: (context, path, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final String? selectedPath =
                                        await getDirectoryPath();
                                    if (selectedPath != null) {
                                      directoryPathNotifier.value =
                                          selectedPath;
                                    }
                                  },
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text("Select save location"),
                                ),
                                if (path != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Selected save location: ...${path.characters.takeLast(15)}",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ValueListenableBuilder(
                      valueListenable: directoryPathNotifier,
                      builder: (context, path, _) {
                        return FilledButton(
                          onPressed: path == null
                              ? null
                              : () {
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                          child: const Text("Start"),
                        );
                      },
                    ),
                  ],
                );
              },
            );

            if (start ?? false) {
              await platform.invokeMethod("startRecording", {
                "name": nameController.text,
                "interval": int.tryParse(intervalController.text) ?? 10,
                "path": directoryPathNotifier.value,
              });

              recordingActionNotifier.value = true;

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Recording ${nameController.text} started...",
                    ),
                  ),
                );
              }
            }

            nameController.dispose();
            intervalController.dispose();
            directoryPathNotifier.dispose();
          },
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
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return errorDialog(context, e);
                  },
                );
              }

              return;
            }
          },
        ),
      ],
    ),
  );
}
