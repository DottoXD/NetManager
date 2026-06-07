import 'package:flutter/material.dart';
import 'package:netmanager/types/database/cell_tower.dart';

Widget towerModal(BuildContext context, CellTower cellTower) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cell tower",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          cellTower.getLatLng().toSexagesimal(),
          style: Theme.of(context).textTheme.bodySmall,
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
                      fontSize: 10,
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
                  "CID: ${cell.cid}. ${cell.channelNumber != null ? "ARFCN: ${cell.channelNumber}" : ""}",
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
