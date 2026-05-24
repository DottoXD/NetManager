import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/record_modal.dart';
import 'package:netmanager/components/utils/cell_utils.dart';
import 'package:netmanager/components/utils/map_overlay.dart';
import 'package:netmanager/components/utils/map_tile_builder.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class MapBody extends StatefulWidget {
  const MapBody(
    this.platform,
    this.sharedPreferences,
    this.platformSignalNotifier,
    this.recordingActionNotifier, {
    super.key,
    this.onPositionButtonPressed,
    this.onRecordButtonPressed,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> recordingActionNotifier;
  final ValueSetter<VoidCallback>? onPositionButtonPressed;
  final ValueSetter<VoidCallback>? onRecordButtonPressed;

  @override
  State<MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<MapBody> with SingleTickerProviderStateMixin {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;
  late ValueNotifier<int> platformSignalNotifier;
  late ValueNotifier<bool> recordingActionNotifier;

  late VoidCallback _signalListener;

  final MapController mapController = MapController();
  final String defaultMapTilesTemplate =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

  RecordedData? _activeReplayData;
  List<Record> _liveRecords = [];
  Record? _selectedRecord;

  Timer? _timer;
  Timer? _liveRecordTimer;
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

  final ValueNotifier<List<String>> displayTitlesNotifier = ValueNotifier([
    "Speed",
    "Cell ID",
    "Signal",
  ]);
  final ValueNotifier<List<String>> displayValuesNotifier = ValueNotifier([
    "N/A",
    "N/A",
    "N/A",
  ]);

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    recordingActionNotifier = widget.recordingActionNotifier;

    metricSystem = sharedPreferences.getBool("metricSystem") ?? true;

    widget.onRecordButtonPressed?.call(() async {
      if (_activeReplayData != null) {
        displayTitlesNotifier.value = <String>["Speed", "Cell ID", "Signal"];
        displayValuesNotifier.value = <String>["N/A", "N/A", "N/A"];

        setState(() {
          _activeReplayData = null;
          recordingActionNotifier.value = false;

          startCellTimer();
          updateLocation();
        });

        if (mounted) recenterMap();

        return;
      }

      if (recordingActionNotifier.value == true) {
        try {
          await platform.invokeMethod("stopRecording");
          recordingActionNotifier.value = false;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Recording stopped and saved.")),
            );

            recenterMap();
            _liveRecordTimer?.cancel();
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

        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (BuildContext context) {
          return recordModal(
            context,
            platform,
            recordingActionNotifier,
            (data) {
              if (data.records.isNotEmpty) {
                displayTitlesNotifier.value = ["Carrier", "PLMN", "Date"];
                displayValuesNotifier.value = [
                  data.operator,
                  data.network,
                  sharedPreferences.getBool("metricSystem") ?? true
                      ? "${data.date.month}/${data.date.day}"
                      : "${data.date.day}/${data.date.month}",
                ];

                setState(() {
                  _activeReplayData = data;
                  recordingActionNotifier.value = true;
                });
                if (_currentLocation != null) {
                  animatedUpdate(
                    _currentLocation!,
                    LatLng(data.records.first.lat, data.records.first.lon),
                    Duration(milliseconds: 500),
                  );
                } else {
                  mapController.move(
                    LatLng(data.records.first.lat, data.records.first.lon),
                    mapController.camera.zoom,
                  );
                }
              }

              _timer?.cancel();
              _cellTimer?.cancel();
            },
            () {
              liveRecordDataPoller();
            },
          );
        },
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPositionButtonPressed?.call(() {
        if (mounted) recenterMap();
      });

      setLocation(false);
      updateLocation();
    });

    startCellTimer();

    _signalListener = restartTimer;
    widget.platformSignalNotifier.addListener(_signalListener);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cellTimer?.cancel();
    _liveRecordTimer?.cancel();

    widget.platformSignalNotifier.removeListener(_signalListener);
    mapController.dispose();

    super.dispose();
  }

  Future<void> setLocation(bool init) async {
    if (_activeReplayData != null) return;

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

          if (_speedKmh > 500) _speedKmh = 0; // hard limit of 500km/h
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
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (mounted) await setLocation(false);
    });
  }

  void updateCellInfo() async {
    try {
      final jsonStr = await platform.invokeMethod("getNetworkData");
      if (jsonStr == null) return;

      final Map<String, dynamic> map = json.decode(jsonStr);
      late final SIMData simData;

      try {
        simData = SIMData.fromJson(map);
      } catch (e) {
        return;
      }

      if (!mounted) return;

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

      displayTitlesNotifier.value = ["Speed", "Cell ID", signalStrengthString];
      displayValuesNotifier.value = [
        (metricSystem
            ? "${_speedKmh.toStringAsFixed(1)}km/h"
            : "${(_speedKmh / 1.609).toStringAsFixed(1)}mph"),
        cellId,
        signalStrength,
      ];

      setState(() {
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

  void animatedUpdate(LatLng from, LatLng to, Duration duration) {
    final tempController = AnimationController(vsync: this, duration: duration);
    final latTween = Tween(begin: from.latitude, end: to.latitude);
    final lngTween = Tween(begin: from.longitude, end: to.longitude);

    tempController.addListener(() {
      if (mounted) {
        mapController.move(
          LatLng(
            latTween.evaluate(tempController),
            lngTween.evaluate(tempController),
          ),
          mapController.camera.zoom,
        );
      }
    });

    tempController.forward().then((_) => tempController.dispose());
  }

  void liveRecordDataPoller() {
    if (_liveRecordTimer != null) return;
    _liveRecordTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (!mounted) return;

      if (recordingActionNotifier.value && _activeReplayData == null) {
        try {
          final String jsonStr = await platform.invokeMethod(
            "getLiveRecording",
          );
          if (jsonStr != null) {
            final Map<String, dynamic> parsedJson = json.decode(jsonStr);
            final List<dynamic> recordsList = parsedJson["records"] ?? [];

            setState(() {
              _liveRecords = recordsList
                  .map((item) => Record.fromJson(item as Map<String, dynamic>))
                  .toList();
            });
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
              ValueListenableBuilder(
                valueListenable: displayValuesNotifier,
                builder: (context, values, child) {
                  return mapOverlay(
                    context,
                    displayTitlesNotifier.value,
                    values,
                  );
                },
              ),

              if (_selectedRecord != null) buildRecordCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget getMap(BuildContext context) {
    const gitCommit = String.fromEnvironment(
      'GIT_COMMIT',
      defaultValue: 'development',
    );

    final List<Record> visualPoints = [];
    if (_activeReplayData != null) {
      visualPoints.addAll(
        _activeReplayData!.records.map(
          (r) => Record(
            networkGen: r.networkGen,
            processedSignal: r.processedSignal,
            usable: r.usable,
            dateTime: r.dateTime,
            lat: r.lat,
            lon: r.lon,
          ),
        ),
      );
    } else if (recordingActionNotifier.value) {
      visualPoints.addAll(_liveRecords);
    }

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
          urlTemplate:
              sharedPreferences.getString("mapTilesTemplate") ??
              defaultMapTilesTemplate,
          tileBuilder: mapTileBuilder,
          userAgentPackageName:
              "pw.dotto.netmanager ($gitCommit) ${sharedPreferences.getString("mapTilesTemplate") != defaultMapTilesTemplate ? "(Customised by user)" : ""}",
        ),
        if (visualPoints.isNotEmpty)
          MarkerLayer(
            markers: visualPoints.map((record) {
              return Marker(
                point: LatLng(record.lat, record.lon),
                width: 14,
                height: 14,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRecord = record;
                      _follow = false;
                    });
                    animatedUpdate(
                      _currentLocation!,
                      LatLng(record.lat, record.lon),
                      Duration(milliseconds: 500),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSignalColor(
                        record.networkGen,
                        record.processedSignal,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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
                    ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white, //color to be changed
                      width: 2,
                    ),
                  ),
                ),
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

  Widget buildRecordCard() {
    final record = _selectedRecord!;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.onSurface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        ),
      ),
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

Color _getSignalColor(int gen, int signal) {
  double strength;

  switch (gen) {
    case 5:
      strength = (signal.clamp(-135, -60) + 135) / 75;
      return const Color(0xFF00C853).withValues(alpha: 0.2 + (strength * 0.7));
    case 4:
      strength = (signal.clamp(-135, -60) + 135) / 75;
      return const Color(0xFF99CC00).withValues(alpha: 0.2 + (strength * 0.7));
    case 3:
      strength = (signal.clamp(-115, -60) + 115) / 55;
      return const Color(0xFFFFAB00).withValues(alpha: 0.2 + (strength * 0.7));
    case 2:
      strength = (signal.clamp(-110, -50) + 110) / 60;
      return const Color(0xFFFF3D00).withValues(alpha: 0.2 + (strength * 0.7));

    default:
      return const Color(0xFF9E9E9E).withValues(alpha: 0.5);
  }
}
