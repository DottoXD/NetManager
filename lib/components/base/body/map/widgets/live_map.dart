import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:netmanager/components/base/body/map/widgets/location_dot.dart';
import 'package:netmanager/components/base/body/map/widgets/visual_records.dart';
import 'package:netmanager/utils/map_tile_builder.dart';
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
  final ValueChanged<Record> onMarkerTap;
  final ValueChanged<bool> onMapInteraction;
  final VoidCallback onMapReady;
  final ValueChanged<bool> onMapLoading;
  final VoidCallback onClearSelection;

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
    required this.onMarkerTap,
    required this.onMapInteraction,
    required this.onMapReady,
    required this.onMapLoading,
    required this.onClearSelection,
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
        initialCenter: currentLocation ?? LatLng(45.464664, 9.188540),
        minZoom: 7.0,
        maxZoom: 16.0,
        initialZoom: 14.0,
        interactionOptions: InteractionOptions(
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
          tileBuilder: mapTileBuilder,
          userAgentPackageName:
              "pw.dotto.netmanager ($gitCommit) ${sharedPreferences.getString("mapTilesTemplate") != defaultMapTilesTemplate ? "(Customised by user)" : ""}",
        ),
        if (visualPoints.isNotEmpty)
          VisualRecords(
            visualPoints: visualPoints,
            selectedRecord: selectedRecord,
            onMarkerTap: onMarkerTap,
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
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const Text("© OpenStreetMap")],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
