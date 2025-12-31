import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/utils/cell_utils.dart';
import 'package:netmanager/components/utils/map_overlay.dart';
import 'package:netmanager/components/utils/map_tile_builder.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class MapBody extends StatefulWidget {
  const MapBody(
    this.platform,
    this.sharedPreferences,
    this.platformSignalNotifier, {
    super.key,
    this.onPositionButtonPressed,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueSetter<VoidCallback>? onPositionButtonPressed;

  @override
  State<MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<MapBody> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;
  late ValueNotifier<int> platformSignalNotifier;

  final MapController mapController = MapController();

  Timer? _timer;
  Timer? _animationTimer;
  LatLng? _currentLocation;

  LatLng? _lastLocation;
  DateTime? _lastUpdateTime;
  double _speedKmh = 0.0;

  bool _follow = true;
  bool _dialogOpen = false;
  bool _isLoading = true;
  bool metricSystem = true;

  Timer? _cellTimer;
  String cellId = "N/A";
  String signalStrength = "N/A";
  String signalStrengthString = "N/A";

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    metricSystem = sharedPreferences.getBool("metricSystem") ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPositionButtonPressed?.call(() {
        if (mounted) recenterMap();
      });

      setLocation(false);
      updateLocation();
    });

    startCellTimer();

    widget.platformSignalNotifier.addListener(() {
      restartTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationTimer?.cancel();
    _cellTimer?.cancel();

    super.dispose();
  }

  Future<void> setLocation(bool init) async {
    try {
      final String jsonString = await platform.invokeMethod("getLocation");
      final List<dynamic> coordinates = json.decode(jsonString);

      final lat = coordinates[0] as double;
      final lon = coordinates[1] as double;

      LatLng newLocation = LatLng(lat, lon);

      if (_lastLocation != null && _lastUpdateTime != null) {
        final dist = Distance().as(
          LengthUnit.Meter,
          _lastLocation!,
          newLocation,
        );
        final time =
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds / 1000.0;

        if (time > 0) {
          final speed = dist / time;
          _speedKmh = speed * 3.6;

          if (_speedKmh > 300) _speedKmh = 0; // hard limit of 300km/h
        }
      }

      _lastLocation = newLocation;
      _lastUpdateTime = DateTime.now();

      LatLng? oldLocation;
      if (_currentLocation != null) {
        oldLocation = _currentLocation!;
      }

      setState(() {
        _currentLocation = LatLng(lat, lon);
      });

      if (init || _follow) {
        if (oldLocation == null) {
          mapController.move(_currentLocation!, mapController.camera.zoom);
        } else {
          animatedUpdate(
            oldLocation,
            _currentLocation!,
            Duration(milliseconds: 500),
          );
        }
      }
    } catch (e) {
      if (!_dialogOpen && mounted) {
        _dialogOpen = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return errorDialog(context, e);
          },
        ).then((_) {
          _dialogOpen = false;
        });
      }
    }
  }

  void recenterMap() {
    setState(() {
      _follow = true;
    });

    setLocation(true);
  }

  void updateLocation() async {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (mounted) await setLocation(false);
    });
  }

  void updateCellInfo() async {
    try {
      final String jsonStr = await platform.invokeMethod("getNetworkData");

      final Map<String, dynamic> map = json.decode(jsonStr);
      late final SIMData simData;

      try {
        simData = SIMData.fromJson(map);
      } catch (e) {
        return;
      }

      if (!mounted) return;

      setState(() {
        signalStrength = "${simData.primaryCell.processedSignal}dBm";
        signalStrengthString = simData.primaryCell.processedSignalString;
        cellId = simData.primaryCell.cellIdentifier;

        if (!isValidInt(simData.primaryCell.processedSignal) ||
            signalStrengthString.trim() == "") {
          if (isValidString(simData.primaryCell.rawSignalString) &&
              isValidInt(simData.primaryCell.rawSignal)) {
            signalStrength = "${simData.primaryCell.rawSignal}dBm";
            signalStrengthString = simData.primaryCell.rawSignalString;
          } else {
            signalStrength = "N/A";
            signalStrengthString = "N/A";
          }
        }

        if (!isValidString(cellId)) {
          cellId = "N/A";
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!_dialogOpen) {
        _dialogOpen = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return errorDialog(context, e);
          },
        ).then((_) {
          _dialogOpen = false;
        });
      }
    }
  }

  void animatedUpdate(LatLng from, LatLng to, Duration duration) async {
    final double frameCount = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .display
        .refreshRate;
    final int msPerFrame = (duration.inMilliseconds / frameCount).round();
    int frame = 0;

    _animationTimer?.cancel();

    _animationTimer = Timer.periodic(Duration(milliseconds: msPerFrame), (
      timer,
    ) {
      frame++;

      double t = frame / frameCount;
      double lat = from.latitude + (to.latitude - from.latitude) * t;
      double lng = from.longitude + (to.longitude - from.longitude) * t;

      mapController.move(LatLng(lat, lng), mapController.camera.zoom);

      if (frame >= frameCount) {
        _animationTimer!.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: [
            Expanded(
              child: _isLoading ? LinearProgressIndicator() : SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              getMap(context),
              mapOverlay(
                context,
                (metricSystem
                    ? "${_speedKmh.toStringAsFixed(1)}km/h"
                    : "${(_speedKmh / 1.609).toStringAsFixed(1)}mph"),
                cellId,
                signalStrengthString,
                signalStrength,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget getMap(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        backgroundColor: Theme.of(context).colorScheme.surface,
        initialCenter: _currentLocation ?? LatLng(45.464664, 9.188540),
        minZoom: 7.0,
        maxZoom: 16.0,
        initialZoom: 14.0,
        interactionOptions: InteractionOptions(
          flags:
              InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
        onMapReady: () {
          setState(() {
            _isLoading = false;
          });
        },
        onMapEvent: (event) {
          if (event is MapEventMoveStart ||
              event is MapEventMove ||
              event is MapEventMoveEnd) {
            _isLoading = event is! MapEventMoveEnd;
            if (event.source == MapEventSource.multiFingerGestureStart ||
                event.source == MapEventSource.multiFingerEnd ||
                event.source == MapEventSource.dragStart ||
                event.source == MapEventSource.dragEnd) {
              if (_follow) {
                setState(() {
                  _follow = false;
                });
              }
            }
          }
        },
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          tileBuilder: mapTileBuilder,
          userAgentPackageName: "pw.dotto.netmanager",
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withAlpha(230),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
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

  void startCellTimer() {
    updateCellInfo();

    _cellTimer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (timer) async {
        if (mounted) updateCellInfo();
      },
    );
  }

  void restartTimer() {
    if (_cellTimer == null) return;

    _cellTimer?.cancel();
    startCellTimer();
  }
}
