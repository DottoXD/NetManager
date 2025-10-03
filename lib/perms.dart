import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Perms extends StatefulWidget {
  const Perms(
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.themeColorNotifier, {
    super.key,
  });
  final SharedPreferences sharedPreferences;

  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<int> themeColorNotifier;

  @override
  State<Perms> createState() => _PermsState();
}

class _PermsState extends State<Perms> with WidgetsBindingObserver {
  static const platform = MethodChannel('pw.dotto.netmanager/telephony');
  bool? hasPermissions;
  bool? isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final result = await platform.invokeMethod<bool>("checkPermissions");
      setState(() {
        hasPermissions = result ?? false;
      });
    } on PlatformException catch (_) {
      setState(() {
        hasPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  "Missing permissions",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "NetManager requires background location and phone permissions to operate.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    await _checkPermissions();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Home(
      widget.sharedPreferences,
      widget.dynamicThemeNotifier,
      widget.themeColorNotifier,
      platform,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((hasPermissions == null || hasPermissions == false) &&
        state == AppLifecycleState.resumed) {
      setState(() {
        isRefreshing = true;
      });

      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          await _checkPermissions();
          setState(() {
            isRefreshing = false;
          });
        }
      });
    }
  }
}
