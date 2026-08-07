import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/share_card.dart';
import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:netmanager/utils/screenshot_helper.dart';

Future<void> shareSpeedtestResult({
  required BuildContext context,
  required MethodChannel platform,
  required SpeedtestHistoryResult result,
  required int unitIndex,
}) async {
  final GlobalKey captureKey = GlobalKey();
  final OverlayState overlay = Overlay.of(context);

  await precacheImage(const AssetImage("assets/icon.png"), context);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: -9999,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: captureKey,
            child: SpeedtestShareCard(
              speedtestResult: result,
              unitIndex: unitIndex,
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 20));

    if (!context.mounted) return;

    await ScreenshotHelper.captureAndShare(
      context: context,
      captureKey: captureKey,
      platform: platform,
    );
  } finally {
    entry.remove();
  }
}
