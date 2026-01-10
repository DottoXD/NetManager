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
  final String sentryDsn = String.fromEnvironment(
    "SENTRY_DSN",
    defaultValue: "",
  );

  if (!analytics || sentryDsn.isEmpty) {
    runApp(const NetManager());
  } else {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.sendDefaultPii = false;
    }, appRunner: () => runApp(const NetManager()));
  }

  if (Platform.isAndroid && (sharedPreferences.getBool("material3") ?? true)) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class NetManager extends StatefulWidget {
  const NetManager({super.key});

  @override
  State<NetManager> createState() => _NetManagerState();
}

class _NetManagerState extends State<NetManager> {
  late SharedPreferences _sharedPreferences;

  bool _prefsLoaded = false;
  bool? _dynamicSupported;

  final ValueNotifier<bool> dynamicThemeNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> themeColorNotifier = ValueNotifier<int>(0xFFE6F0F2);
  final ValueNotifier<bool> material3Notifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    dynamicThemeNotifier.dispose();
    themeColorNotifier.dispose();
    material3Notifier.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();

    dynamicThemeNotifier.value =
        _sharedPreferences.getBool("dynamicTheme") ?? true;
    themeColorNotifier.value =
        _sharedPreferences.getInt("themeColor") ?? 0xFFE6F0F2;
    material3Notifier.value = _sharedPreferences.getBool("material3") ?? true;

    setState(() => _prefsLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

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
              _sharedPreferences.setBool("dynamicSupported", dynamicAvailable);
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
                _sharedPreferences,
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

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({required this.danger});

  final Color? danger;

  @override
  CustomColors copyWith({Color? danger}) {
    return CustomColors(danger: danger ?? this.danger);
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(danger: Color.lerp(danger, other.danger, t));
  }

  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith(danger: danger!.harmonizeWith(dynamic.primary));
  }
}
