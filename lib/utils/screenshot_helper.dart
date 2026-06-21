import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotHelper {
  static Future<void> captureAndShare({
    required BuildContext context,
    required GlobalKey captureKey,
    required MethodChannel platform,
  }) async {
    try {
      final dir = await getTemporaryDirectory();

      final exportFolder = Directory("${dir.path}/exports");
      if (!exportFolder.existsSync()) {
        await exportFolder.create();
      }

      RenderRepaintBoundary boundary =
          captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final file = File(
        "${exportFolder.path}/${DateTime.now().toIso8601String().replaceAll(":", "-")}.png",
      );
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Screenshot saved at: ${file.path}"),
            showCloseIcon: true,
          ),
        );
      }

      await platform.invokeMethod("share", {"path": file.path});
    } catch (e) {
      if (context.mounted) {
        await platform.invokeMethod<bool>("showToast", {
          "message": AppLocalizations.of(context)!.unexpectedError,
        });
      }
    }
  }
}
