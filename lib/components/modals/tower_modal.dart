import 'package:material_ui/material_ui.dart';
import 'package:netmanager/types/database/cell_tower.dart';

class TowerModal extends StatelessWidget {
  const TowerModal({super.key, required this.cellTower});

  final CellTower cellTower;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cellTower.getLatLng().toSexagesimal(),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cellTower.cells.length,
                itemBuilder: (context, index) {
                  final cell = cellTower.cells[index];
                  final Color genColor = cell.networkGen == 5
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.primary;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: genColor.withValues(alpha: 0.15),
                      child: Text(
                        "${cell.networkGen}G",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: genColor,
                        ),
                      ),
                    ),
                    title: Text(
                      cell.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "CID: ${cell.cid}. ${cell.channelNumber != null && cell.channelNumber != 0 ? "ARFCN: ${cell.channelNumber}" : ""}",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
