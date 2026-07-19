import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/home/widgets/cell_list_item.dart';
import 'package:netmanager/types/cell/cell_data.dart';

class CellSection extends StatelessWidget {
  final String title;
  final List<CellData> cells;
  final int factor;
  final bool isActive;
  final Map<int, String> descriptions;

  const CellSection({
    super.key,
    required this.title,
    required this.cells,
    required this.factor,
    required this.isActive,
    required this.descriptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells.map((cell) {
              int nodeVal = 0;
              final parsed = int.tryParse(cell.cellIdentifier);
              if (parsed != null) nodeVal = parsed;

              return CellListItem(
                cell: cell,
                nodeVal: nodeVal,
                factor: factor,
                showSignalIcon: isActive,
                showDivider:
                    !isActive && cells.indexOf(cell) != cells.length - 1,
                description: descriptions[nodeVal],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
