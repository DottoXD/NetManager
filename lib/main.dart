import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
//import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'home.dart';

void main() async {
  /*SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  bool? analytics = sharedPreferences.getBool("analytics");
  String sentryDsn = String.fromEnvironment("SENTRY_DSN", defaultValue: "");

  if (analytics == null || !analytics || sentryDsn.isEmpty) {
    runApp(NetManager());
  } else {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.sendDefaultPii = false;
    }, appRunner: () => runApp(NetManager()));
  }*/

  runApp(NetManager());

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class NetManager extends StatefulWidget {
  const NetManager({super.key});

  @override
  State<NetManager> createState() => _NetManagerState();
}

class _NetManagerState extends State<NetManager> {
  late Future<SharedPreferences> _tempSharedPreferences;
  late ColorScheme _lightColorScheme;
  late ColorScheme _darkColorScheme;

  final ValueNotifier<bool> dynamicThemeNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _tempSharedPreferences = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _tempSharedPreferences,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final sharedPreferences = snapshot.data!;
          Color color = Color(
            sharedPreferences.getInt("backgroundColor") ?? 0xFFE6F0F2,
          );
          dynamicThemeNotifier.value =
              sharedPreferences.getBool("dynamicTheme") ?? true;

          return ValueListenableBuilder(
            valueListenable: dynamicThemeNotifier,
            builder: (context, dynamicTheme, _) {
              return DynamicColorBuilder(
                builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
                  if (lightDynamic == null && darkDynamic == null) {
                    sharedPreferences.setBool("dynamicSupported", false);
                  } else {
                    sharedPreferences.setBool("dynamicSupported", true);
                  }

                  if (lightDynamic != null &&
                      darkDynamic != null &&
                      dynamicTheme) {
                    _lightColorScheme = lightDynamic.harmonized();
                    _darkColorScheme = darkDynamic.harmonized();
                  } else {
                    _lightColorScheme = ColorScheme.fromSeed(seedColor: color);
                    _darkColorScheme = ColorScheme.fromSeed(
                      seedColor: color,
                      brightness: Brightness.dark,
                    );
                  }

                  return MaterialApp(
                    theme: ThemeData(colorScheme: _lightColorScheme),
                    darkTheme: ThemeData(colorScheme: _darkColorScheme),
                    home: Home(sharedPreferences, dynamicThemeNotifier),
                    debugShowCheckedModeBanner: false,
                  );
                },
              );
            },
          );
        } else {
          return const CircularProgressIndicator();
        }
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
