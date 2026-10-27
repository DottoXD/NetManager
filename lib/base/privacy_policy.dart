import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:url_launcher/url_launcher.dart';

const int privacyPolicyVersion = 3;

class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback onReviewed;
  final VoidCallback? onCancel;

  const PrivacyConsentScreen({
    super.key,
    required this.onReviewed,
    this.onCancel,
  });

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  Future<void> _openPrivacyPolicy() async {
    await HapticService().triggerHaptic(HapticType.light, context);

    final uri = Uri.parse(
      "https://raw.githubusercontent.com/DottoXD/NetManager/refs/heads/main/PRIVACY.md",
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.privacy_tip_outlined,
                                  size: 72,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 32),
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
                                label: Text(
                                  appLocalizations.privacyPolicyReadFull,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () async {
                                    await HapticService().triggerHaptic(
                                      HapticType.medium,
                                      context,
                                    );
                                    widget.onReviewed();
                                  },
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                  child: Text(appLocalizations.privacyPolicyOk),
                                ),
                              ),
                              if (widget.onCancel != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: widget.onCancel,
                                  child: Text(
                                    appLocalizations.privacyPolicyBack,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
