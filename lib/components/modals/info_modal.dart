import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget infoModal(BuildContext context, MethodChannel platform) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.settings_input_antenna_outlined),
          title: const Text("Radio Info"),
          onTap: () async => await platform.invokeMethod("openRadioInfo"),
        ),
        ListTile(
          leading: const Icon(Icons.engineering_outlined),
          title: const Text("Telephony UI"),
          onTap: () async => await platform.invokeMethod("openSamsungInfo"),
        ),
      ],
    ),
  );
}
