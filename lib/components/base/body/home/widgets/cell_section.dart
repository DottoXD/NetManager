import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/home/widgets/cell_list_item.dart';
import 'package:netmanager/types/cell/cell_data.dart';
import 'package:netmanager/utils/cell_utils.dart';

class CellSection extends StatelessWidget {
  final String title;
  final List<CellData> cells;
  final bool isActive;
  final Map<int, String> descriptions;
  final Map<int, ({int cid, bool strongMatch})> guessedCids;

  const CellSection({
    super.key,
    required this.title,
    required this.cells,
    required this.isActive,
    required this.descriptions,
    required this.guessedCids,
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
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 18),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (int i = 0; i < cells.length; i++) _buildItem(i)],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int i) {
    final CellData cell = cells[i];

    int nodeVal = 0;
    bool strongGuess = true;

    final int? parsedCid = int.tryParse(cell.cellIdentifier);
    if (parsedCid != null &&
        isValidString(cell.cellIdentifier) &&
        parsedCid != 0) {
      nodeVal = parsedCid;
    } else if (guessedCids.containsKey(i)) {
      final guess = guessedCids[i]!;
      nodeVal = guess.cid;
      strongGuess = guess.strongMatch;
    }

    return CellListItem(
      cell: cell,
      nodeVal: nodeVal,
      strongGuess: strongGuess,
      factor: conversionFactor(cell),
      showSignalIcon: isActive,
      showDivider: !isActive && i != cells.length - 1,
      description: descriptions[nodeVal],
    );
  }
}
