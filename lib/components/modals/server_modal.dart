import 'package:flutter/material.dart';

Widget serverModal(
  BuildContext context,
  List<dynamic> servers,
  ValueNotifier<Map<String, dynamic>?> selectedServerNotifier,
) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: servers.length,
    itemBuilder: (context, i) => ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text("${servers[i]["sponsorName"]} (${servers[i]["name"]})"),
      onTap: () {
        selectedServerNotifier.value = servers[i];
        Navigator.pop(context);
      },
    ),
  );
}
