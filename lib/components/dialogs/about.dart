import 'package:flutter/material.dart';

Widget aboutDialog() {
  return AboutDialog(
    applicationLegalese: "${DateTime.now().year} @ DottoXD",
    applicationName: "NetManager",
    //applicationIcon as soon as i make an icon
    //applicationVersio maybe?
  );
}
