import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

Widget infoModal(BuildContext context, MethodChannel platform) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HapticTap(
          type: HapticType.SELECTION,
          child: ListTile(
            leading: const Icon(Icons.settings_input_antenna_outlined),
            title: const Text("Radio Info"),
            onTap: () async => await platform.invokeMethod("openRadioInfo"),
          ),
        ),
        HapticTap(
          type: HapticType.SELECTION,
          child: ListTile(
            leading: const Icon(Icons.engineering_outlined),
            title: const Text("Telephony UI"),
            onTap: () async => await platform.invokeMethod("openSamsungInfo"),
          ),
        ),
      ],
    ),
  );
}
