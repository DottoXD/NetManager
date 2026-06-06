import 'package:flutter/material.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/types/cell/sim_data.dart';

class NetworkData extends StatelessWidget {
  final SIMData simData;
  final double cardWidth;
  final double cardHeight;

  const NetworkData({
    super.key,
    required this.simData,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    int timingAdvanceDistance = 0;
    if (simData.primaryCell.channelNumberString == "ARFCN") {
      // terrible (yet working) way of detecting gsm...
      timingAdvanceDistance = simData.primaryCell.timingAdvance * 550;
    } else {
      timingAdvanceDistance = simData.primaryCell.timingAdvance * 78; // 78.12
    }

    final List<String> elements = [
      simData.primaryCell.rawSignalString,
      "${simData.primaryCell.rawSignal}dBm",
      simData.primaryCell.processedSignalString,
      "${simData.primaryCell.processedSignal}dBm",
      simData.primaryCell.signalQualityString,
      "${simData.primaryCell.signalQuality}dB",
      simData.primaryCell.signalNoiseString,
      "${simData.primaryCell.signalNoise}dB",
      simData.primaryCell.channelNumberString,
      simData.primaryCell.channelNumber.toString(),
      simData.primaryCell.stationIdentityString,
      simData.primaryCell.stationIdentity.toString(),
      simData.primaryCell.areaCodeString,
      simData.primaryCell.areaCode.toString(),
      simData.primaryCell.timingAdvanceString,
      (timingAdvanceDistance <= 0
          ? simData.primaryCell.timingAdvance.toString()
          : "${simData.primaryCell.timingAdvance} (${timingAdvanceDistance}m)"),
      simData.primaryCell.bandwidthString,
      "${simData.activeBw}MHz",
      simData.primaryCell.bandString,
      simData.primaryCell.band.toString(),
    ];

    final List<Widget> validCards = [];

    for (int i = 0; i < elements.length - 1; i += 2) {
      final String label = elements[i];
      final String val = elements[i + 1];

      if (!isValidString(val) || !isValidString(label)) {
        continue;
      }

      validCards.add(
        Tooltip(
          message: label,
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha(230),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(val),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          getTrailingIcon(simData, label),
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < validCards.length; i += 2) {
      final Widget leftCard = validCards[i];
      final Widget rightCard = (i + 1 < validCards.length)
          ? validCards[i + 1]
          : Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.symmetric(vertical: 5),
            );

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
                child: leftCard,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
                child: rightCard,
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}
