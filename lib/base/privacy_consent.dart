import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:url_launcher/url_launcher.dart';

const int privacyPolicyVersion = 1;

class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback onAccept;

  const PrivacyConsentScreen({super.key, required this.onAccept});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  final ValueNotifier<bool> _hasReadPrivacyPolicyNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  void dispose() {
    _hasReadPrivacyPolicyNotifier.dispose();
    super.dispose();
  }

  Future<void> _openPrivacyPolicy() async {
    await HapticService().triggerHaptic(HapticType.light, context);

    final uri = Uri.parse(
      "https://raw.githubusercontent.com/DottoXD/NetManager/refs/heads/main/PRIVACY.md",
    );

    await launchUrl(uri);

    if (mounted) {
      _hasReadPrivacyPolicyNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          size: 64,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        appLocalizations.privacyPolicyTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appLocalizations.privacyPolicyDescription,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _openPrivacyPolicy,
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: Text(appLocalizations.privacyPolicyReadFull),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerHigh,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _hasReadPrivacyPolicyNotifier,
                          builder: (context, hasReadPolicy, child) {
                            return CheckboxListTile(
                              value: hasReadPolicy,
                              onChanged: (value) {
                                HapticService().triggerHaptic(
                                  HapticType.selection,
                                  context,
                                );
                                _hasReadPrivacyPolicyNotifier.value =
                                    value ?? false;
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                appLocalizations.privacyPolicyAcceptCheckbox,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _hasReadPrivacyPolicyNotifier,
                    builder: (context, hasReadPolicy, child) {
                      return FilledButton(
                        onPressed: hasReadPolicy
                            ? () async {
                                await HapticService().triggerHaptic(
                                  HapticType.medium,
                                  context,
                                );
                                widget.onAccept();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(appLocalizations.privacyPolicyAccept),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
