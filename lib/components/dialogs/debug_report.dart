import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class DebugReportDialog extends StatefulWidget {
  final MethodChannel platform;

  const DebugReportDialog({super.key, required this.platform});

  @override
  State<DebugReportDialog> createState() => _DebugReportDialogState();
}

class _DebugReportDialogState extends State<DebugReportDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ValueNotifier<bool> _isSendingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorMessageNotifier = ValueNotifier<String?>(
    null,
  );

  late MethodChannel platform;

  @override
  void initState() {
    super.initState();

    platform = widget.platform;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _isSendingNotifier.dispose();
    _errorMessageNotifier.dispose();

    super.dispose();
  }

  Future<void> _sendDebugReport(AppLocalizations appLocalizations) async {
    _isSendingNotifier.value = true;
    _errorMessageNotifier.value = null;

    try {
      final String? rawJson = await platform.invokeMethod<String>(
        "getDebugReport",
      );
      final Map<String, dynamic> debugData = rawJson != null
          ? jsonDecode(rawJson)
          : {};

      final userMessage = _messageController.text.trim();
      final reportTitle = userMessage.isNotEmpty ? userMessage : "Debug Report";

      final SentryId eventId = await Sentry.captureMessage(
        reportTitle,
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setContexts("debug_report", debugData);
          if (userMessage.isNotEmpty) {
            scope.setExtra("user_message", userMessage);
          }
        },
      );

      if (!mounted) return;

      if (eventId != const SentryId.empty()) {
        Navigator.of(context).pop(true);
      } else {
        _isSendingNotifier.value = false;
        _errorMessageNotifier.value = appLocalizations.debugReportError;
      }
    } catch (e) {
      if (!mounted) return;
      _isSendingNotifier.value = false;
      _errorMessageNotifier.value = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(appLocalizations.settingsDebugReportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.debugReportInstructions,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: _isSendingNotifier,
              builder: (context, isSending, child) {
                return TextField(
                  controller: _messageController,
                  maxLength: 100,
                  maxLines: 3,
                  enabled: !isSending,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: appLocalizations.debugReportHint,
                    counterText: null,
                  ),
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: _errorMessageNotifier,
              builder: (context, errorMessage, child) {
                if (errorMessage == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: _isSendingNotifier,
          builder: (context, isSending, child) {
            return TextButton(
              onPressed: () async {
                await HapticService().triggerHaptic(
                  HapticType.selection,
                  context,
                );

                if (!isSending && context.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(appLocalizations.close),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: _isSendingNotifier,
          builder: (context, isSending, child) {
            return FilledButton(
              onPressed: () async {
                await HapticService().triggerHaptic(
                  HapticType.selection,
                  context,
                );

                if (!isSending) _sendDebugReport(appLocalizations);
              },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(appLocalizations.send),
            );
          },
        ),
      ],
    );
  }
}
