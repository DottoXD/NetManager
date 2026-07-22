import 'package:netmanager/types/database/cell_tower.dart';

class TowerFilter {
  static const List<int> mobileGenerations = [2, 3, 4, 5];

  final Set<int>? allowedGenerations;
  final int? minCellCount;

  const TowerFilter({this.allowedGenerations, this.minCellCount});

  bool isActive() {
    return allowedGenerations != null || minCellCount != null;
  }

  bool towerMatches(CellTower tower) {
    if (allowedGenerations != null &&
        !allowedGenerations!.contains(tower.getMaxGen())) {
      return false;
    }

    if (minCellCount != null && tower.cells.length < minCellCount!) {
      return false;
    }

    return true;
  }

  TowerFilter copyWith({
    Set<int>? allowedGenerations,
    bool clearAllowedGenerations = false,
    int? minCellCount,
    bool clearMinCellCount = false,
  }) {
    return TowerFilter(
      allowedGenerations: clearAllowedGenerations
          ? null
          : (allowedGenerations ?? this.allowedGenerations),
      minCellCount: clearMinCellCount
          ? null
          : (minCellCount ?? this.minCellCount),
    );
  }
}
