import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:netmanager/components/base/body/map/widgets/bearing_line.dart';
import 'package:netmanager/components/base/body/map/widgets/cell_towers.dart';
import 'package:netmanager/components/base/body/map/widgets/location_dot.dart';
import 'package:netmanager/components/base/body/map/widgets/visual_records.dart';
import 'package:netmanager/types/database/cell_tower.dart';
import 'package:netmanager/components/base/body/map/widgets/map_tile_builder.dart';
import 'package:netmanager/types/map/tower_filter.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveMap extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final Record? selectedRecord;
  final bool recordingActive;
  final List<Record> liveRecords;
  final RecordedData? activeReplayData;
  final bool followUser;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<List<CellTower>> cellTowersNotifier;
  final Function(MapCamera camera) onPositionChanged;
  final ValueChanged<Record> onMarkerTap;
  final ValueChanged<bool> onMapInteraction;
  final VoidCallback onMapReady;
  final ValueChanged<bool> onMapLoading;
  final VoidCallback onClearSelection;
  final Function(LatLng latLng) onTowerTap;
  final ValueNotifier<CellTower?> connectedTowerNotifier;
  final ValueNotifier<TowerFilter> towerFilterNotifier;
  final bool showBearingLine;

  final String defaultMapTilesTemplate =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

  const LiveMap({
    super.key,
    required this.mapController,
    required this.currentLocation,
    required this.selectedRecord,
    required this.recordingActive,
    required this.liveRecords,
    required this.activeReplayData,
    required this.followUser,
    required this.sharedPreferences,
    required this.cellTowersNotifier,
    required this.onPositionChanged,
    required this.onMarkerTap,
    required this.onMapInteraction,
    required this.onMapReady,
    required this.onMapLoading,
    required this.onClearSelection,
    required this.onTowerTap,
    required this.connectedTowerNotifier,
    required this.towerFilterNotifier,
    required this.showBearingLine,
  });

  @override
  Widget build(BuildContext context) {
    const gitCommit = String.fromEnvironment(
      'GIT_COMMIT',
      defaultValue: 'development',
    );

    final List<Record> visualPoints = [];
    if (activeReplayData != null) {
      visualPoints.addAll(activeReplayData!.records);
    } else if (recordingActive) {
      visualPoints.addAll(liveRecords);
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        backgroundColor: Theme.of(context).colorScheme.surface,
        initialCenter: currentLocation ?? const LatLng(45.464664, 9.188540),
        minZoom: 7.0,
        maxZoom: 16.0,
        initialZoom: 14.0,
        onPositionChanged: (camera, hasGesture) {
          onPositionChanged(camera);
        },
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
        onMapReady: onMapReady,
        onMapEvent: (event) {
          if (event is MapEventMoveStart ||
              event is MapEventMove ||
              event is MapEventMoveEnd) {
            onMapLoading(event is! MapEventMoveEnd);

            if (event.source == MapEventSource.multiFingerGestureStart ||
                event.source == MapEventSource.multiFingerEnd ||
                event.source == MapEventSource.dragStart ||
                event.source == MapEventSource.dragEnd) {
              onMapInteraction(true);
            }
          }
        },
        onTap: (tapPosition, point) => onClearSelection(),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              sharedPreferences.getString("mapTilesTemplate") ??
              defaultMapTilesTemplate,
          tileBuilder: (context, tileWidget, tile) =>
              MapTileBuilder(tileWidget: tileWidget),
          userAgentPackageName:
              "pw.dotto.netmanager ($gitCommit) ${sharedPreferences.getString("mapTilesTemplate") != defaultMapTilesTemplate ? "(Customised by user)" : ""}",
        ),
        ValueListenableBuilder(
          valueListenable: connectedTowerNotifier,
          builder: (context, connectedTower, _) {
            return ValueListenableBuilder(
              valueListenable: towerFilterNotifier,
              builder: (context, towerFilter, _) {
                final bool isTowerVisible =
                    connectedTower != null &&
                    (!towerFilter.isActive() ||
                        towerFilter.towerMatches(connectedTower));

                if (showBearingLine &&
                    currentLocation != null &&
                    isTowerVisible) {
                  return BearingLine(
                    userLocation: currentLocation!,
                    towerLocation: connectedTower.getLatLng(),
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
        if (visualPoints.isNotEmpty)
          VisualRecords(
            visualPoints: visualPoints,
            selectedRecord: selectedRecord,
            onMarkerTap: onMarkerTap,
          ),
        ValueListenableBuilder(
          valueListenable: cellTowersNotifier,
          builder: (context, cellTowers, _) {
            if (cellTowers.isEmpty) return const SizedBox.shrink();

            return ValueListenableBuilder(
              valueListenable: towerFilterNotifier,
              builder: (context, towerFilter, _) {
                final filteredTowers = towerFilter.isActive()
                    ? cellTowers.where(towerFilter.towerMatches).toList()
                    : cellTowers;

                if (filteredTowers.isEmpty) return const SizedBox.shrink();

                return ValueListenableBuilder(
                  valueListenable: connectedTowerNotifier,
                  builder: (context, connectedTower, _) {
                    return CellTowers(
                      cellTowers: filteredTowers,
                      connectedTower: connectedTower,
                      onTowerTap: onTowerTap,
                    );
                  },
                );
              },
            );
          },
        ),
        if (currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
                width: 20,
                height: 20,
                child: const LocationDot(),
              ),
            ],
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: GestureDetector(
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text("© OpenStreetMap"),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
