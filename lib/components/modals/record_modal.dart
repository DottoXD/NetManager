import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/utils/haptic_service.dart';

Widget recordModal(
  BuildContext context,
  MethodChannel platform,
  ValueNotifier<bool> recordingActionNotifier,
  Function(RecordedData) onDataLoaded,
  Function() triggerPooler,
) {
  AppLocalizations appLocalizations = AppLocalizations.of(context)!;
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.fiber_smart_record_outlined),
          title: Text(appLocalizations.newRecording),
          subtitle: Text(appLocalizations.recordingSetupDialog),
          onTap: () async {
            final TextEditingController nameController = TextEditingController(
              text: "NetManager_${DateTime.now().millisecondsSinceEpoch}",
            );
            final TextEditingController intervalController =
                TextEditingController(text: "10");
            final TextEditingController
            usabilityTestUrlController = TextEditingController(
              text: "https://connectivitycheck.grapheneos.network/generate_204",
            );
            final ValueNotifier<String?> directoryPathNotifier = ValueNotifier(
              null,
            );
            final ValueNotifier<bool> trackUsableNotifier = ValueNotifier(
              false,
            );

            final bool? start = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(appLocalizations.newRecording),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.fileName,
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
                          decoration: InputDecoration(
                            labelText: appLocalizations.recordingInterval,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<bool>(
                          valueListenable: trackUsableNotifier,
                          builder: (context, trackUsable, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  title: Text(appLocalizations.trackUsability),
                                  value: trackUsable,
                                  onChanged: (bool value) async {
                                    await HapticService().triggerHaptic(
                                      HapticType.selection,
                                      context,
                                    );

                                    trackUsableNotifier.value = value;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: usabilityTestUrlController,
                                  decoration: InputDecoration(
                                    labelText:
                                        appLocalizations.usabilityTestUrl,
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: trackUsable,
                                ),
                              ],
                            );
                          },
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
                                  label: Text(
                                    appLocalizations.selectSaveLocation,
                                  ),
                                ),
                                if (path != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "${appLocalizations.selectedSaveLocation} ...${path.characters.takeLast(15)}",
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
                      child: Text(appLocalizations.cancel),
                    ),
                    ValueListenableBuilder(
                      valueListenable: directoryPathNotifier,
                      builder: (context, path, _) {
                        return FilledButton.icon(
                          onPressed: path == null
                              ? null
                              : () async {
                                  await HapticService().triggerHaptic(
                                    HapticType.selection,
                                    context,
                                  );

                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                          icon: const Icon(Icons.fiber_smart_record_outlined),
                          label: Text(appLocalizations.start),
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
                "trackUsable": trackUsableNotifier.value,
                "usabilityTestUrl": usabilityTestUrlController.text,
              });

              recordingActionNotifier.value = true;

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appLocalizations.recordingStarted(nameController.text),
                    ),
                  ),
                );
              }

              triggerPooler();
            }

            nameController.dispose();
            intervalController.dispose();
            directoryPathNotifier.dispose();
            trackUsableNotifier.dispose();
            usabilityTestUrlController.dispose();
          },
        ),
        ListTile(
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
                    return errorDialog(
                      context,
                      "${appLocalizations.replayRecording}: $e",
                    );
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
