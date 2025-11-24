import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FullAboutDialog extends StatelessWidget {
  final MethodChannel platform;

  const FullAboutDialog({required this.platform, super.key});

  static const gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'development',
  );

  Future<String> getVersion() async {
    try {
      final version = await platform.invokeMethod("getVersion");
      return version ?? "Unknown";
    } on PlatformException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stacktrace);
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getVersion(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? "N/A";
        return AboutDialog(
          applicationLegalese: "${DateTime.now().year} @ DottoXD",
          applicationName: "NetManager",
          applicationIcon: Builder(
            builder: (context) {
              bool lightTheme =
                  Theme.of(context).brightness == Brightness.light;
              Image img = Image.asset("assets/icon.png", width: 48, height: 48);

              if (!lightTheme) {
                return ColorFiltered(
                  colorFilter: ColorFilter.matrix(<double>[
                    -1, 0, 0, 0, 255, // red
                    0, -1, 0, 0, 255, // green
                    0, 0, -1, 0, 255, // blue
                    0, 0, 0, 1, 0,
                  ]),
                  child: img,
                );
              }

              return img;
            },
          ),
          applicationVersion: "$version ($gitCommit)",
        );
      },
    );
  }
}
