import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

Widget recordModal(BuildContext context, MethodChannel platform) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HapticTap(
          type: HapticType.SELECTION,
          child: ListTile(
            leading: const Icon(Icons.fiber_smart_record_outlined),
            title: const Text("New recording"),
            subtitle: const Text(
              "You will be taken to the recording setup dialog.",
            ),
            onTap: () async => (),
          ),
        ),
        HapticTap(
          type: HapticType.SELECTION,
          child: ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text("Replay recording"),
            subtitle: const Text(
              "You will be asked to select a valid .nmr (NetManager Recording) file.",
            ),
            onTap: () async => (),
          ),
        ),
      ],
    ),
  );
}
