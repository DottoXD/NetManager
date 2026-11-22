import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/storage/storage_directory.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/storage_utils.dart';

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
    text: "NetManager_Recording_${DateTime.now().millisecondsSinceEpoch}",
  );
  late final TextEditingController _intervalController = TextEditingController(
    text: "10",
  );
  late final TextEditingController _usabilityTestUrlController =
      TextEditingController(
        text: "https://connectivitycheck.grapheneos.network/generate_204",
      );
  late final ValueNotifier<StorageDirectory?> _directoryNotifier =
      ValueNotifier(null);
  late final ValueNotifier<int> _pendingRecordingNotifier = ValueNotifier(0);
  late final ValueNotifier<bool> _recoveringNotifier = ValueNotifier(false);
  late final ValueNotifier<bool> _trackUsableNotifier = ValueNotifier(false);
  late final ValueNotifier<bool> _dualSimNotifier = ValueNotifier(false);

  int _simCount = 1;

  @override
  void initState() {
    super.initState();
    _loadSimCount();
    _loadPendingRecordingCount();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _usabilityTestUrlController.dispose();
    _directoryNotifier.dispose();
    _pendingRecordingNotifier.dispose();
    _recoveringNotifier.dispose();
    _trackUsableNotifier.dispose();
    _dualSimNotifier.dispose();

    super.dispose();
  }

  Future<void> _loadSimCount() async {
    final count = await widget.platform.invokeMethod<int>("getSimCount");
    if (mounted) setState(() => _simCount = count ?? 1);
  }

  Future<void> _loadPendingRecordingCount() async {
    try {
      final int count = await StorageUtils.getPendingRecordingCount();
      if (mounted) _pendingRecordingNotifier.value = count;
    } catch (_) {}
  }

  Future<void> _retryPendingRecordings() async {
    if (_recoveringNotifier.value) return;
    _recoveringNotifier.value = true;

    try {
      final result = await StorageUtils.retryPendingRecordings(
        directoryUri: _directoryNotifier.value?.uri,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.recordingsExported(result.exported),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => ErrorDialog(e: e),
        );
      }
    } finally {
      if (mounted) {
        await _loadPendingRecordingCount();
        if (mounted) _recoveringNotifier.value = false;
      }
    }
  }

  Future<void> _openSetupDialog() async {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    final bool? start = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.emergency_recording_outlined),
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
                if (_simCount > 1) ...[
                  const SizedBox(height: 16),
                  ValueListenableBuilder(
                    valueListenable: _dualSimNotifier,
                    builder: (context, dualSim, _) {
                      return SwitchListTile(
                        title: Text(appLocalizations.recordingDualSimTitle),
                        subtitle: Text(
                          appLocalizations.recordingDualSimDescription,
                        ),
                        value: dualSim,
                        onChanged: (val) async {
                          await HapticService().triggerHaptic(
                            HapticType.selection,
                            context,
                          );

                          _dualSimNotifier.value = val;
                        },
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                ValueListenableBuilder<StorageDirectory?>(
                  valueListenable: _directoryNotifier,
                  builder: (context, directory, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final StorageDirectory? selectedDirectory =
                                  await StorageUtils.pickDirectory();

                              if (selectedDirectory != null) {
                                _directoryNotifier.value = selectedDirectory;
                              }
                            } catch (e) {
                              if (context.mounted) {
                                await showDialog(
                                  context: context,
                                  builder: (context) => ErrorDialog(e: e),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: Text(appLocalizations.selectSaveLocation),
                        ),
                        if (directory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${appLocalizations.selectedSaveLocation} ${directory.name}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _pendingRecordingNotifier,
                  builder: (context, pending, _) {
                    if (pending == 0) return const SizedBox.shrink();
                    return ValueListenableBuilder<bool>(
                      valueListenable: _recoveringNotifier,
                      builder: (context, recovering, _) => Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: recovering
                              ? null
                              : _retryPendingRecordings,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            appLocalizations.retryRecordingExports(pending),
                          ),
                        ),
                      ),
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
              valueListenable: _directoryNotifier,
              builder: (context, directory, _) {
                return FilledButton.icon(
                  onPressed: directory == null
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

    try {
      await widget.platform.invokeMethod("startRecording", {
        "name": _nameController.text,
        "interval": interval,
        "path": _directoryNotifier.value?.uri,
        "dualSimMode": _dualSimNotifier.value,
        "trackUsable": _trackUsableNotifier.value,
        "usabilityTestUrl": _usabilityTestUrlController.text,
      });
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => ErrorDialog(e: e),
        );
      }
      return;
    }

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
