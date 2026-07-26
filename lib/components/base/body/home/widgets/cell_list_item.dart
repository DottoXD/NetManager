import 'dart:math';

import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/types/cell/cell_data.dart';

class CellListItem extends StatelessWidget {
  final CellData cell;
  final int nodeVal;
  final int factor;
  final bool showSignalIcon;
  final bool showDivider;
  final String? description;
  final bool strongGuess;

  const CellListItem({
    super.key,
    required this.cell,
    required this.nodeVal,
    required this.factor,
    required this.showSignalIcon,
    required this.showDivider,
    required this.strongGuess,
    this.description,
  });

  int _calculateIconIndex() {
    const int minRssi = -113, maxRssi = -51;
    const int minRsrp = -140, maxRsrp = -43;
    int index = 4;

    if (isValidInt(cell.processedSignal)) {
      index =
          ((min(max(cell.processedSignal, minRsrp), (maxRsrp - 15)) - minRsrp) /
                  (((maxRsrp - 15) - minRsrp) / 2))
              .floor();
    } else if (isValidInt(cell.rawSignal)) {
      index =
          ((min(max(cell.rawSignal, minRssi), (maxRssi - 15)) - minRssi) /
                  (((maxRssi - 15) - minRssi) / 2))
              .floor();
    }
    if (index != 4 && cell.isRegistered) index += 2;
    return index;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    String cellContent = createCellContent(context, cell).replaceAll(
      "%node%",
      (nodeVal != 0
          ? "${strongGuess ? appLocalizations.likely : appLocalizations.possibly} ${(nodeVal / factor).floor()}"
          : appLocalizations.unknownCell),
    );

    if (description != null && description!.isNotEmpty) {
      cellContent = "$description.\n$cellContent";
    }

    List<IconData> icons = [
      Icons.signal_cellular_0_bar_outlined,
      Icons.signal_cellular_4_bar_outlined,
      Icons.auto_awesome_outlined,
      Icons.auto_awesome_rounded,
      Icons.question_mark,
    ];

    return Column(
      children: [
        ListTile(
          title: Text(
            (cell.basicCellData.band > 0
                ? "${cell.channelNumberString == "NR-ARFCN" ? "N" : "B"}${cell.basicCellData.band} ${isValidInt(cell.basicCellData.frequency) ? "(${cell.basicCellData.frequency}MHz)" : ""}"
                : appLocalizations.unknownBand),
          ),
          subtitle: Text(cellContent),
          trailing: showSignalIcon
              ? Icon(
                  icons[_calculateIconIndex()],
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                )
              : null,
        ),
        if (showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Divider(
              height: 0,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}
