import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/screen_utils.dart';
import 'package:netmanager/base/perms.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  await HapticService().init(sharedPreferences);

  if (isPhone()) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final bool analytics = sharedPreferences.getBool("analytics") ?? false;
  const String sentryDsn = String.fromEnvironment(
    "SENTRY_DSN",
    defaultValue: "",
  );

  if (!analytics || sentryDsn.isEmpty) {
    runApp(NetManager(prefs: sharedPreferences));
  } else {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.sendDefaultPii = false;
      options.tracesSampleRate = 1;
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
  final ValueNotifier<bool> harmonizedColorsNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<int> themeColorNotifier = ValueNotifier<int>(0xFFE6F0F2);
  final ValueNotifier<bool> material3Notifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> darkThemeNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

  @override
  void initState() {
    super.initState();

    dynamicThemeNotifier.value = widget.prefs.getBool("dynamicTheme") ?? true;
    harmonizedColorsNotifier.value =
        widget.prefs.getBool("harmonizedColors") ?? true;
    themeColorNotifier.value = widget.prefs.getInt("themeColor") ?? 0xFFE6F0F2;
    material3Notifier.value = widget.prefs.getBool("material3") ?? true;

    if (widget.prefs.containsKey("darkTheme")) {
      darkThemeNotifier.value = widget.prefs.getBool("darkTheme") ?? true;
    } else {
      final Brightness systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final bool systemPrefersDark = systemBrightness == Brightness.dark;

      darkThemeNotifier.value = systemPrefersDark;
      widget.prefs.setBool("darkTheme", systemPrefersDark);
    }

    final String? langCode = widget.prefs.getString("languageCode");
    localeNotifier.value = langCode != null ? Locale(langCode) : null;
  }

  @override
  void dispose() {
    dynamicThemeNotifier.dispose();
    harmonizedColorsNotifier.dispose();
    themeColorNotifier.dispose();
    material3Notifier.dispose();
    darkThemeNotifier.dispose();
    localeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        dynamicThemeNotifier,
        harmonizedColorsNotifier,
        themeColorNotifier,
        material3Notifier,
        darkThemeNotifier,
        localeNotifier,
      ]),
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final bool dynamicAvailable =
                lightDynamic != null && darkDynamic != null;

            if (_dynamicSupported != dynamicAvailable) {
              _dynamicSupported = dynamicAvailable;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.prefs.setBool("dynamicSupported", dynamicAvailable);
              });
            }

            final bool useDynamic =
                dynamicAvailable && dynamicThemeNotifier.value;
            final ColorScheme lightScheme;
            final ColorScheme darkScheme;

            if (lightDynamic != null && darkDynamic != null && useDynamic) {
              if (harmonizedColorsNotifier.value) {
                lightScheme = lightDynamic.harmonized();
                darkScheme = darkDynamic.harmonized();
              } else {
                lightScheme = ColorScheme.fromSeed(
                  seedColor: lightDynamic.primary,
                  brightness: Brightness.light,
                );
                darkScheme = ColorScheme.fromSeed(
                  seedColor: darkDynamic.primary,
                  brightness: Brightness.dark,
                );
              }
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

            const transitionTheme = PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              },
            );

            return MaterialApp(
              theme: ThemeData(
                colorScheme: lightScheme,
                useMaterial3: material3Notifier.value,
                pageTransitionsTheme: transitionTheme,
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: material3Notifier.value,
                pageTransitionsTheme: transitionTheme,
              ),
              themeMode: darkThemeNotifier.value
                  ? ThemeMode.dark
                  : ThemeMode.light,
              builder: (context, child) {
                return Builder(
                  builder: (innerContext) {
                    final isDark =
                        Theme.of(innerContext).brightness == Brightness.dark;

                    return AnnotatedRegion(
                      value: SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: isDark
                            ? Brightness.light
                            : Brightness.dark,
                        statusBarBrightness: isDark
                            ? Brightness.dark
                            : Brightness.light,
                        systemNavigationBarColor: Theme.of(innerContext)
                            .colorScheme
                            .surface, // sdk < 27 -> make it Colors.black
                        systemNavigationBarIconBrightness: isDark
                            ? Brightness.light
                            : Brightness.dark,
                      ),
                      child: child!,
                    );
                  },
                );
              },
              home: Perms(
                widget.prefs,
                dynamicThemeNotifier,
                harmonizedColorsNotifier,
                themeColorNotifier,
                material3Notifier,
                darkThemeNotifier,
                localeNotifier,
              ),
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: localeNotifier.value,
            );
          },
        );
      },
    );
  }
}
