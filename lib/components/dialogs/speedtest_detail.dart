import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:netmanager/utils/speed_methods.dart';
import 'package:url_launcher/url_launcher.dart';

class SpeedtestDetailDialog extends StatelessWidget {
  const SpeedtestDetailDialog({
    super.key,
    required this.speedtestResult,
    required this.unitIndex,
  });

  final SpeedtestHistoryResult speedtestResult;
  final int unitIndex;

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      title: Text(
        DateFormat("dd/MM/yyyy HH:mm:ss").format(speedtestResult.timestamp),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _detailRow(
              context,
              "Download",
              "${formatSpeed(speedtestResult.download, unitIndex)} ${getUnitString(unitIndex)}",
            ),
            _detailRow(
              context,
              "Upload",
              "${formatSpeed(speedtestResult.upload, unitIndex)} ${getUnitString(unitIndex)}",
            ),
            _detailRow(context, "Ping", "${speedtestResult.ping} ms"),
            _detailRow(context, "Jitter", "${speedtestResult.jitter} ms"),
            _detailRow(
              context,
              "Loss",
              "${speedtestResult.packetLoss.toStringAsFixed(1)}%",
            ),
            _detailRow(context, "Gen", speedtestResult.getNetworkGenLabel()),
            _detailRow(
              context,
              appLocalizations.speedtestCarrier,
              speedtestResult.carrier,
            ),
            _detailRow(context, "PLMN", speedtestResult.plmn),
            if (speedtestResult.serverName != null)
              _detailRow(
                context,
                appLocalizations.speedtestServer,
                speedtestResult.serverName!,
              ),
            if (speedtestResult.hasLocation())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLocalizations.speedtestLocation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final Uri url = Uri.parse(
                          "https://maps.google.com/?q=${speedtestResult.latitude},${speedtestResult.longitude}",
                        );
                        launchUrl(url);
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(
                        "${speedtestResult.latitude!.toStringAsFixed(4)}, ${speedtestResult.longitude!.toStringAsFixed(4)}",
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLocalizations.close),
        ),
      ],
    );
  }
}
