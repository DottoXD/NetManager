import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/base/onboarding.dart';
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
    this.themeColorNotifier,
    this.material3Notifier,
    this.localeNotifier, {
    super.key,
  });
  final SharedPreferences sharedPreferences;

  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final ValueNotifier<bool> material3Notifier;
  final ValueNotifier<Locale?> localeNotifier;

  @override
  State<Perms> createState() => _PermsState();
}

class _PermsState extends State<Perms> with WidgetsBindingObserver {
  static const platform = MethodChannel('pw.dotto.netmanager/bridge');

  bool? hasPermissions;
  bool isRefreshing = false;
  bool _showOnboarding = true;

  static final int _requiredPerms =
      Permissions.READ_PHONE_STATE |
      Permissions.ACCESS_FINE_LOCATION |
      Permissions.ACCESS_BACKGROUND_LOCATION;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    if (hasPermissions == null || isRefreshing == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasPermissions == false) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 24),
                Text(
                  appLocalizations.missingPermissions,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.requiredPermissions,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () async {
                    await HapticService().triggerHaptic(
                      HapticType.light,
                      context,
                    );

                    await _requestPermissions();
                    await _checkPermissions();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(appLocalizations.allow),
                ),
              ],
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
      widget.themeColorNotifier,
      widget.material3Notifier,
      widget.localeNotifier,
      platform,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((hasPermissions == null || hasPermissions == false) &&
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
