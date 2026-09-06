import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class ScheduleSpeedtestDialog extends StatefulWidget {
  final MethodChannel platform;
  final String serverName;
  final String pingUrl;
  final String downloadUrl;
  final String uploadUrl;

  const ScheduleSpeedtestDialog({
    super.key,
    required this.platform,
    required this.serverName,
    required this.pingUrl,
    required this.downloadUrl,
    required this.uploadUrl,
  });

  static Future<int?> show(
    BuildContext context, {
    required MethodChannel platform,
    required String serverName,
    required String pingUrl,
    required String downloadUrl,
    required String uploadUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ScheduleSpeedtestDialog(
        platform: platform,
        serverName: serverName,
        pingUrl: pingUrl,
        downloadUrl: downloadUrl,
        uploadUrl: uploadUrl,
      ),
    );
  }

  @override
  State<ScheduleSpeedtestDialog> createState() =>
      _ScheduleSpeedtestDialogState();
}

class _ScheduleSpeedtestDialogState extends State<ScheduleSpeedtestDialog> {
  final ValueNotifier<bool> _isIgnoringBatteryOptimisations =
      ValueNotifier<bool>(true);

  late final TextEditingController _intervalController = TextEditingController(
    text: "5",
  );

  @override
  void initState() {
    super.initState();
    checkBatteryOptimization();
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _isIgnoringBatteryOptimisations.dispose();
    super.dispose();
  }

  Future<void> _startSchedule() async {
    final int minutes = (int.tryParse(_intervalController.text) ?? 5).clamp(
      1,
      1440,
    );
    final int intervalMs = minutes * 60 * 1000;

    await widget.platform.invokeMethod("startScheduledTest", {
      "pingUrl": widget.pingUrl,
      "downloadUrl": widget.downloadUrl,
      "uploadUrl": widget.uploadUrl,
      "intervalMs": intervalMs,
    });

    if (!mounted) return;

    Navigator.of(context).pop(minutes);
  }

  Future<void> checkBatteryOptimization() async {
    try {
      final bool isIgnoring =
          await widget.platform.invokeMethod(
            "isIgnoringBatteryOptimisations",
          ) ??
          true;

      _isIgnoringBatteryOptimisations.value = isIgnoring;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(appLocalizations.speedtestPlan),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _isIgnoringBatteryOptimisations,
              builder: (context, isIgnoring, child) {
                if (isIgnoring) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  color: Theme.of(context).colorScheme.errorContainer
                      .withValues(alpha: 0.5),
                  child: ListTile(
                    title: Text(
                      appLocalizations.settingsBatteryOptimisationTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 13.0,
                      ),
                    ),
                    subtitle: Text(
                      appLocalizations.settingsBatteryOptimisationDescription,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 11.0,
                      ),
                    ),
                    trailing: FilledButton.icon(
                      onPressed: () async {
                        await HapticService().triggerHaptic(
                          HapticType.selection,
                          context,
                        );

                        await widget.platform.invokeMethod(
                          "requestIgnoreBatteryOptimisations",
                        );

                        await checkBatteryOptimization();
                      },
                      label: Text(appLocalizations.fix),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _intervalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: appLocalizations.speedtestPlanInterval,
                hintText: "1 - 1440",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(appLocalizations.cancel),
        ),
        FilledButton.icon(
          onPressed: () async {
            await HapticService().triggerHaptic(HapticType.selection, context);

            await _startSchedule();
          },
          icon: const Icon(Icons.alarm_add_outlined),
          label: Text(appLocalizations.schedule),
        ),
      ],
    );
  }
}
