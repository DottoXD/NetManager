import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/types/base/info_menu_option.dart';

class InfoModal extends StatelessWidget {
  const InfoModal({super.key, required this.platform, required this.options});

  final MethodChannel platform;
  final List<InfoMenuOption> options;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return ListTile(
            leading: Icon(option.icon),
            title: Text(option.title),
            onTap: () async {
              Navigator.pop(context);
              await platform.invokeMethod(option.method);
            },
          );
        }).toList(),
      ),
    );
  }
}
