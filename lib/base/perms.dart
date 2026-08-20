import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/base/onboarding.dart';
import 'package:netmanager/base/privacy_consent.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/check_update.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/base/home.dart';
import 'package:netmanager/types/device/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Perms extends StatefulWidget {
  const Perms(
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.harmonizedColorsNotifier,
    this.themeColorNotifier,
    this.material3Notifier,
    this.darkThemeNotifier,
    this.localeNotifier, {
    super.key,
  });
  final SharedPreferences sharedPreferences;

  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<bool> harmonizedColorsNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final ValueNotifier<bool> material3Notifier;
  final ValueNotifier<bool> darkThemeNotifier;
  final ValueNotifier<Locale?> localeNotifier;

  @override
  State<Perms> createState() => _PermsState();
}

class _PermsState extends State<Perms> with WidgetsBindingObserver {
  static const platform = MethodChannel('pw.dotto.netmanager/bridge');

  bool? hasPermissions;
  bool isRefreshing = false;
  bool _showOnboarding = true;
  bool _hasAcceptedPrivacyPolicy = false;

  static const int _requiredPerms =
      Permissions.READ_PHONE_STATE |
      Permissions.ACCESS_FINE_LOCATION |
      Permissions.ACCESS_BACKGROUND_LOCATION;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      _hasAcceptedPrivacyPolicy =
          widget.sharedPreferences.getInt("privacyPolicyAcceptedVersion") ==
          privacyPolicyVersion;
    } catch (e) {}

    if (_hasAcceptedPrivacyPolicy) {
      _startPostPrivacyFlow();
    }
  }

  void _startPostPrivacyFlow() {
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (hasPermissions == false) {
        await _requestPermissions();
      }

      if (widget.sharedPreferences.getBool("checkUpdates") != true) return;
      bool updateAvailable = await checkForUpdate();

      if (updateAvailable && mounted) {
        await platform.invokeMethod<bool>("showToast", {
          "message": AppLocalizations.of(context)!.updateAvailable,
        });
      }
    });
  }

  Future<void> _acceptPrivacyPolicy() async {
    await widget.sharedPreferences.setInt(
      "privacyPolicyAcceptedVersion",
      privacyPolicyVersion,
    );

    if (!mounted) return;

    setState(() => _hasAcceptedPrivacyPolicy = true);
    _startPostPrivacyFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final result = await platform.invokeMethod<bool>("checkPermissions", {
        "perms": _requiredPerms,
      });

      final seenTutorial =
          widget.sharedPreferences.getBool("seenOnboarding") ?? false;

      final newValue = result ?? false;

      if (hasPermissions != newValue && mounted) {
        setState(() {
          hasPermissions = result ?? false;
          _showOnboarding = !seenTutorial;
        });
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() => hasPermissions = false);
    }
  }

  Future<void> _requestPermissions() async {
    await platform.invokeMethod<bool>("requestPermissions", {
      "perms": _requiredPerms,
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (!_hasAcceptedPrivacyPolicy) {
      return PrivacyConsentScreen(onAccept: _acceptPrivacyPolicy);
    }

    if (hasPermissions == null || isRefreshing == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasPermissions == false) {
      final requiredPermissions = [
        (
          icon: Icons.perm_phone_msg_outlined,
          label: appLocalizations.permissionPhoneState,
        ),
        (
          icon: Icons.location_on_outlined,
          label: appLocalizations.permissionLocation,
        ),
        (
          icon: Icons.location_history_outlined,
          label: appLocalizations.permissionBackgroundLocation,
        ),
      ];

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock_outlined,
                      size: 64,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    appLocalizations.missingPermissions,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.requiredPermissions,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: requiredPermissions.map((perm) {
                        return ListTile(
                          leading: Icon(
                            perm.icon,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            perm.label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await HapticService().triggerHaptic(
                          HapticType.light,
                          context,
                        );

                        await _requestPermissions();
                        await _checkPermissions();
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(appLocalizations.allow),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        appLocalizations: appLocalizations,
        onFinished: () async {
          await widget.sharedPreferences.setBool("seenOnboarding", true);
          setState(() => _showOnboarding = false);
        },
      );
    }

    return Home(
      widget.sharedPreferences,
      widget.dynamicThemeNotifier,
      widget.harmonizedColorsNotifier,
      widget.themeColorNotifier,
      widget.material3Notifier,
      widget.darkThemeNotifier,
      widget.localeNotifier,
      platform,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasAcceptedPrivacyPolicy &&
        (hasPermissions == null || hasPermissions == false) &&
        state == AppLifecycleState.resumed) {
      setState(() => isRefreshing = true);

      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          await _requestPermissions();
          await _checkPermissions();

          setState(() => isRefreshing = false);
        }
      });
    }
  }
}
