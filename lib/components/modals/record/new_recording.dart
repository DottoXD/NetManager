import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class NewRecording extends StatefulWidget {
  const NewRecording({
    super.key,
    required this.platform,
    required this.recordingActionNotifier,
    required this.onRecordingStarted,
  });

  final MethodChannel platform;
  final ValueNotifier<bool> recordingActionNotifier;
  final void Function() onRecordingStarted;

  @override
  State<NewRecording> createState() => _NewRecordingState();
}

class _NewRecordingState extends State<NewRecording> {
  late final TextEditingController _nameController = TextEditingController(
    text: "NetManager_${DateTime.now().millisecondsSinceEpoch}",
  );
  late final TextEditingController _intervalController = TextEditingController(
    text: "10",
  );
  late final TextEditingController _usabilityTestUrlController =
      TextEditingController(
        text: "https://connectivitycheck.grapheneos.network/generate_204",
      );
  late final ValueNotifier<String?> _directoryPathNotifier = ValueNotifier(
    null,
  );
  late final ValueNotifier<bool> _trackUsableNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _usabilityTestUrlController.dispose();
    _directoryPathNotifier.dispose();
    _trackUsableNotifier.dispose();

    super.dispose();
  }

  Future<void> _openSetupDialog() async {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

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
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.fileName,
                    suffixText: ".nmr",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: appLocalizations.recordingInterval,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _trackUsableNotifier,
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

                            _trackUsableNotifier.value = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usabilityTestUrlController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.usabilityTestUrl,
                            border: const OutlineInputBorder(),
                          ),
                          enabled: trackUsable,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _directoryPathNotifier,
                  builder: (context, path, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final String? selectedPath =
                                await getDirectoryPath();
                            if (selectedPath != null) {
                              _directoryPathNotifier.value = selectedPath;
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: Text(appLocalizations.selectSaveLocation),
                        ),
                        if (path != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${appLocalizations.selectedSaveLocation} ...${path.characters.takeLast(15)}",
                              style: Theme.of(context).textTheme.bodySmall,
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
              valueListenable: _directoryPathNotifier,
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

    if (!(start ?? false)) return;

    final int interval = (int.tryParse(_intervalController.text) ?? 10).clamp(
      1,
      300,
    );

    await widget.platform.invokeMethod("startRecording", {
      "name": _nameController.text,
      "interval": interval,
      "path": _directoryPathNotifier.value,
      "trackUsable": _trackUsableNotifier.value,
      "usabilityTestUrl": _usabilityTestUrlController.text,
    });

    widget.recordingActionNotifier.value = true;

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations.recordingStarted(_nameController.text),
          ),
        ),
      );
    }

    widget.onRecordingStarted();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.fiber_smart_record_outlined),
      title: Text(appLocalizations.newRecording),
      subtitle: Text(appLocalizations.recordingSetupDialog),
      onTap: _openSetupDialog,
    );
  }
}
