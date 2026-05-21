import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget serverModal(
  BuildContext context,
  List<dynamic> servers,
  ValueNotifier<Map<String, dynamic>?> selectedServerNotifier,
) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: servers.length,
    itemBuilder: (context, i) => ListTile(
      leading: const Icon(Icons.open_in_new),
      title: Text("${servers[i]["sponsorName"]} (${servers[i]["name"]})"),
      trailing: servers[i]["sponsorURL"] != null
          ? IconButton(
              onPressed: () {
                Uri url = Uri.parse(servers[i]["sponsorURL"]);
                launchUrl(url);
              },
              icon: Icon(Icons.open_in_new),
              tooltip: "Visit the server's host in a browser",
            )
          : null,
      onTap: () {
        selectedServerNotifier.value = servers[i];
        Navigator.pop(context);
      },
    ),
  );
}
