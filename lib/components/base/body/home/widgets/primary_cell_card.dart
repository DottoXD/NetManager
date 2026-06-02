import 'package:flutter/material.dart';
import 'package:netmanager/types/cell/cell_data.dart';

class PrimaryCellCard extends StatelessWidget {
  final CellData cell;
  final ValueNotifier<bool> altCellView;
  final int factor;
  final VoidCallback onToggle;
  final double cardWidth;
  final double cardHeight;

  const PrimaryCellCard({
    super.key,
    required this.cell,
    required this.altCellView,
    required this.factor,
    required this.onToggle,
    required this.cardWidth,
    required this.cardHeight,
  });

  bool isUnknown() {
    return cell.cellIdentifier.contains("-1") || cell.cellIdentifier == "0";
  }

  String _getTooltip(bool altCellView) {
    if (isUnknown()) {
      return "Unknown";
    } else {
      return altCellView
          ? "${cell.cellIdentifierString} (${cell.cellIdentifier})"
          : "${cell.nodeIdentifierString}/CID (${((int.tryParse(cell.cellIdentifier) ?? 0) / factor).floor()}/${(int.tryParse(cell.cellIdentifier) ?? 0) % factor})";
    }
  }

  String _getUtilText(bool altCellView) {
    return altCellView
        ? cell.cellIdentifierString
        : "${cell.nodeIdentifierString}/CID";
  }

  String _getTitle(bool altCellView) {
    if (isUnknown()) {
      return "Unknown";
    } else {
      return altCellView
          ? cell.cellIdentifier
          : "${((int.tryParse(cell.cellIdentifier) ?? 0) / factor).floor()}/${(int.tryParse(cell.cellIdentifier) ?? 0) % factor}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
            child: ValueListenableBuilder(
              valueListenable: altCellView,
              builder: (context, altCellView, child) {
                return Tooltip(
                  message: _getTooltip(altCellView),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      overlayColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withAlpha(35),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      //margin: EdgeInsets.only(bottom: 5),
                      padding: EdgeInsets.zero,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    onPressed: onToggle,
                    child: Ink(
                      width: cardWidth * 2,
                      height: (cardHeight * 2) - 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (!(isUnknown())) ...[
                            Text(
                              _getUtilText(altCellView),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.cell_tower_outlined,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getTitle(altCellView),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
