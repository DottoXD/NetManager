import 'package:flutter/material.dart';

bool isPhone() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final size = dispatcher.views.first.physicalSize;
  final pixelRatio = dispatcher.views.first.devicePixelRatio;

  final width = size.width / pixelRatio;
  final height = size.height / pixelRatio;
  final shortestSide = width < height ? width : height;

  if (shortestSide < 600) {
    return true;
  } else {
    return false;
  }
}
