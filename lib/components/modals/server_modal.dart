import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:url_launcher/url_launcher.dart';

Widget serverModal(
  BuildContext context,
  List<dynamic> servers,
  ValueNotifier<Map<String, dynamic>?> selectedServerNotifier,
) {
  return ListView.builder(
    shrinkWrap: true,
    padding: const EdgeInsets.only(bottom: 16),
    itemCount: servers.length,
    itemBuilder: (context, i) {
      final sponsorName = servers[i]["sponsorName"];

      return ListTile(
        title: Text(
          "$sponsorName (${(servers[i]["name"]).toString().replaceAll(" ($sponsorName)", "")})",
        ),
        trailing: servers[i]["sponsorURL"] != null
            ? IconButton(
                onPressed: () async {
                  await HapticService().triggerHaptic(
                    HapticType.selection,
                    context,
                  );

                  Uri url = Uri.parse(servers[i]["sponsorURL"]);
                  launchUrl(url);
                },
                icon: Icon(Icons.open_in_new),
                tooltip: AppLocalizations.of(context)!.visitServerHost,
              )
            : null,
        onTap: () async {
          await HapticService().triggerHaptic(HapticType.selection, context);

          selectedServerNotifier.value = servers[i];
          if (context.mounted) Navigator.pop(context);
        },
      );
    },
  );
}
