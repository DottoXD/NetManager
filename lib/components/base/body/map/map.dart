import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
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
          _selectedRecord = null;
          _liveRecords = [];
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
            _selectedRecord = null;
            _liveRecords = [];
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
                      ? "${data.date.day}/${data.date.month}"
                      : "${data.date.month}/${data.date.day}",
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

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      reverseDuration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: _selectedRecord != null
                          ? buildRecordCard()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
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
      visualPoints.addAll(_activeReplayData!.records);
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
        onTap: (tapPosition, point) {
          if (_selectedRecord != null) {
            setState(() {
              _selectedRecord = null;
            });
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
              final isSelected =
                  _selectedRecord != null &&
                  _selectedRecord!.dateTime == record.dateTime;

              return Marker(
                point: LatLng(record.lat, record.lon),
                width: isSelected ? 20 : 14,
                height: isSelected ? 20 : 14,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRecord = record;
                      _follow = false;
                    });

                    animatedUpdate(
                      mapController.camera.center,
                      LatLng(record.lat, record.lon),
                      Duration(milliseconds: 500),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSignalColor(
                        record.networkGen,
                        record.processedSignal,
                      ).withValues(alpha: record.usable ? 1.0 : 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isSelected ? 0.4 : 0.2,
                          ),
                          blurRadius: isSelected ? 4 : 2,
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

    int index = -1;
    if (_liveRecords.isNotEmpty) {
      index = _liveRecords.indexOf(_selectedRecord!);
    } else if (_activeReplayData != null &&
        _activeReplayData!.records.isNotEmpty) {
      index = _activeReplayData!.records.indexOf(_selectedRecord!);
    }

    return Padding(
      key: ValueKey(record.dateTime.toString()),
      padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${index >= 0 ? "Record #$index - " : ""}${record.networkGen < 2 ? "N/A" : "${record.networkGen}G"}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_outlined, size: 24),
                    tooltip: "Close record card",
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _selectedRecord = null;
                      });
                    },
                  ),
                ],
              ),
              const Divider(height: 4),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Signal Strength",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Timestamp",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (!record.usable) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Network was unusable (Ping timed out)",
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${record.processedSignal}dBm",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          "dd/MM/yyyy HH:mm:ss",
                        ).format(record.dateTime.toLocal()),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
