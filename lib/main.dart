import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/perms.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  final bool analytics = sharedPreferences.getBool("analytics") ?? false;
  const String sentryDsn = String.fromEnvironment(
    "SENTRY_DSN",
    defaultValue: "",
  );

  if (!analytics || sentryDsn.isEmpty) {
    runApp(NetManager(prefs: sharedPreferences));
  } else {
    FlutterError.onError = (FlutterErrorDetails details) async {
      await Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      Sentry.captureException(error, stackTrace: stack);
      return true;
    };

    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.sendDefaultPii = false;
      options.tracesSampleRate = 1;
      options.debug = true;
    }, appRunner: () => runApp(NetManager(prefs: sharedPreferences)));
  }

  if (Platform.isAndroid && (sharedPreferences.getBool("material3") ?? true)) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class NetManager extends StatefulWidget {
  final SharedPreferences prefs;
  const NetManager({super.key, required this.prefs});

  @override
  State<NetManager> createState() => _NetManagerState();
}

class _NetManagerState extends State<NetManager> {
  bool? _dynamicSupported;

  final ValueNotifier<bool> dynamicThemeNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> themeColorNotifier = ValueNotifier<int>(0xFFE6F0F2);
  final ValueNotifier<bool> material3Notifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    dynamicThemeNotifier.value = widget.prefs.getBool("dynamicTheme") ?? true;
    themeColorNotifier.value = widget.prefs.getInt("themeColor") ?? 0xFFE6F0F2;
    material3Notifier.value = widget.prefs.getBool("material3") ?? true;
  }

  @override
  void dispose() {
    dynamicThemeNotifier.dispose();
    themeColorNotifier.dispose();
    material3Notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        dynamicThemeNotifier,
        themeColorNotifier,
        material3Notifier,
      ]),
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final bool dynamicAvailable =
                lightDynamic != null && darkDynamic != null;

            if (_dynamicSupported != dynamicAvailable) {
              _dynamicSupported = dynamicAvailable;
              widget.prefs.setBool("dynamicSupported", dynamicAvailable);
            }

            final bool useDynamic =
                dynamicAvailable && dynamicThemeNotifier.value;
            final ColorScheme lightScheme;
            final ColorScheme darkScheme;

            if (lightDynamic != null && darkDynamic != null && useDynamic) {
              lightScheme = lightDynamic.harmonized();
              darkScheme = darkDynamic.harmonized();
            } else {
              final seedColor = Color(themeColorNotifier.value);

              lightScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              );
              darkScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              );
            }

            return MaterialApp(
              theme: ThemeData(
                colorScheme: lightScheme,
                useMaterial3: material3Notifier.value,
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: material3Notifier.value,
              ),
              home: Perms(
                widget.prefs,
                dynamicThemeNotifier,
                themeColorNotifier,
                material3Notifier,
              ),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
