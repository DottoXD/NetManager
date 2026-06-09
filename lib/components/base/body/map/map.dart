import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:netmanager/components/base/body/map/widgets/live_map.dart';
import 'package:netmanager/components/base/body/map/widgets/record_card.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/record_modal.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/types/database/cell_tower.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/components/base/body/map/widgets/map_overlay.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:netmanager/utils/simdata_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class MapBody extends StatefulWidget {
  const MapBody(
    this.platform,
    this.sharedPreferences,
    this.platformSignalNotifier,
    this.recordingActionNotifier,
    this.updateIntervalNotifier,
    this.metricSystemNotifier,
    this.mapTilesTemplateNotifier,
    this.databaseCellsInMapNotifier,
    this.externalDatabaseNotifier, {
    super.key,
    this.onPositionButtonPressed,
    this.onRecordButtonPressed,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> recordingActionNotifier;

  final ValueNotifier<int> updateIntervalNotifier;
  final ValueNotifier<bool> metricSystemNotifier;
  final ValueNotifier<String> mapTilesTemplateNotifier;
  final ValueNotifier<bool> databaseCellsInMapNotifier;
  final ValueNotifier<bool> externalDatabaseNotifier;

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
  late VoidCallback _updateIntervalListener;

  final MapController _mapController = MapController();
  late AnimationController _animationController;

  RecordedData? _activeReplayData;
  List<Record> _liveRecords = [];
  Record? _selectedRecord;

  Timer? _timer;
  Timer? _liveRecordTimer;
  LatLng? _currentLocation;
  Timer? _mapLoadingDebounce;

  LatLng? _lastLocation;
  DateTime? _lastUpdateTime;
  double _speedKmh = 0.0;

  bool _follow = true;
  bool _dialogOpen = false;

  Timer? _cellTimer;
  String cellId = "N/A";
  String signalStrength = "N/A";
  String signalStrengthString = "N/A";

  LatLngBounds? _cachedBounds;
  String _lastPlmn = "";
  bool _isMapReady = false;
  double? _lastQueryZoom;
  bool _towerQueryInProgress = false;

  final ValueNotifier<List<CellTower>> _cellTowersNotifier = ValueNotifier([]);

  final ValueNotifier<List<String>> _displayTitlesNotifier = ValueNotifier([
    "Speed",
    "Cell ID",
    "Signal",
  ]);
  final ValueNotifier<List<String>> _displayValuesNotifier = ValueNotifier([
    "N/A",
    "N/A",
    "N/A",
  ]);

  final ValueNotifier<bool> _mapLoadingNotifier = ValueNotifier(true);

  bool get _metricSystem => widget.metricSystemNotifier.value;
  int get _updateInterval => widget.updateIntervalNotifier.value;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);

    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    recordingActionNotifier = widget.recordingActionNotifier;

    widget.databaseCellsInMapNotifier.addListener(_onTowerSettingsChanged);
    widget.externalDatabaseNotifier.addListener(_onTowerSettingsChanged);

    _updateIntervalListener = () {
      _cellTimer?.cancel();
      startCellTimer();
      _timer?.cancel();
      updateLocation();
    };

    widget.updateIntervalNotifier.addListener(_updateIntervalListener);

    widget.onRecordButtonPressed?.call(() async {
      if (_activeReplayData != null) {
        _displayTitlesNotifier.value = <String>["Speed", "Cell ID", "Signal"];
        _displayValuesNotifier.value = <String>["N/A", "N/A", "N/A"];

        setState(() {
          _activeReplayData = null;
          recordingActionNotifier.value = false;

          _cellTimer?.cancel();
          startCellTimer();

          _timer?.cancel();
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
                return errorDialog(context, "Stop recording: $e");
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
        showDragHandle: true,
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
              try {
                if (data.records.isNotEmpty) {
                  _displayTitlesNotifier.value = ["Carrier", "PLMN", "Date"];
                  _displayValuesNotifier.value = [
                    data.operator,
                    data.network,
                    _metricSystem
                        ? "${data.date.day}/${data.date.month}"
                        : "${data.date.month}/${data.date.day}",
                  ];

                  setState(() {
                    _activeReplayData = data;
                    recordingActionNotifier.value = true;
                  });
                  if (_currentLocation != null) {
                    animatedUpdate(
                      _mapController.camera.center,
                      LatLng(data.records.first.lat, data.records.first.lon),
                      Duration(milliseconds: 500),
                    );
                  } else {
                    _mapController.move(
                      LatLng(data.records.first.lat, data.records.first.lon),
                      _mapController.camera.zoom,
                    );
                  }
                }
              } catch (e) {
                if (!_dialogOpen && mounted) {
                  _dialogOpen = true;
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return errorDialog(
                        context,
                        "Please select a valid recording.",
                      );
                    },
                  ).then((_) {
                    _dialogOpen = false;
                  });
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
      _timer?.cancel();
      updateLocation();
    });

    _cellTimer?.cancel();
    startCellTimer();

    _signalListener = restartTimer;
    widget.platformSignalNotifier.addListener(_signalListener);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cellTimer?.cancel();
    _liveRecordTimer?.cancel();
    _mapLoadingDebounce?.cancel();

    widget.platformSignalNotifier.removeListener(_signalListener);
    widget.updateIntervalNotifier.removeListener(_updateIntervalListener);

    widget.databaseCellsInMapNotifier.removeListener(_onTowerSettingsChanged);
    widget.externalDatabaseNotifier.removeListener(_onTowerSettingsChanged);

    _mapController.dispose();
    _animationController.dispose();

    _cellTowersNotifier.dispose();
    _displayTitlesNotifier.dispose();
    _displayValuesNotifier.dispose();
    _mapLoadingNotifier.dispose();

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
        if (newLocation.latitude != _lastLocation!.latitude ||
            newLocation.longitude != _lastLocation!.longitude) {
          final dist = Distance().as(
            LengthUnit.Meter,
            _lastLocation!,
            newLocation,
          );
          final time =
              DateTime.now().difference(_lastUpdateTime!).inMilliseconds /
              1000.0;

          if (time > 0) {
            final speed = dist / time;
            _speedKmh = speed * 3.6;

            if (_speedKmh > 500) _speedKmh = 0; // hard limit of 500km/h
          }

          _lastLocation = newLocation;
          _lastUpdateTime = DateTime.now();
        } else {
          if (DateTime.now().difference(_lastUpdateTime!).inSeconds > 10) {
            _speedKmh = 0.0;
          }
        }
      } else {
        _lastLocation = newLocation;
        _lastUpdateTime = DateTime.now();
      }

      LatLng? oldLocation;
      if (_currentLocation != null) {
        oldLocation = _currentLocation!;
      }

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });
      }

      if (init || _follow) {
        if (oldLocation == null) {
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        } else {
          animatedUpdate(
            _mapController.camera.center,
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
            return errorDialog(context, "Map: $e");
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
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (mounted) await setLocation(false);
    });
  }

  void updateCellInfo() async {
    try {
      final jsonStr = await platform.invokeMethod("getNetworkData");
      if (jsonStr == null) return;

      final SIMData? simData;

      try {
        simData = await compute<String, SIMData?>(parseSimData, jsonStr);
      } catch (e) {
        return;
      }

      if (!mounted || simData == null) return;

      final String currentPlmn = simData.networkPlmn;
      final bool plmnChanged = _lastPlmn != currentPlmn;
      _lastPlmn = currentPlmn;

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

      _displayTitlesNotifier.value = ["Speed", "Cell ID", signalStrengthString];
      _displayValuesNotifier.value = [
        (_metricSystem
            ? "${_speedKmh.toStringAsFixed(1)}km/h"
            : "${(_speedKmh / 1.609).toStringAsFixed(1)}mph"),
        cellId,
        signalStrength,
      ];

      _mapLoadingNotifier.value = false;

      if (plmnChanged) {
        _cachedBounds = null;
        _lastQueryZoom = null;

        if (_isMapReady) {
          checkAndLoadTowers(_mapController.camera.visibleBounds);
        }
      }
    } catch (e) {
      if (!_dialogOpen) {
        _dialogOpen = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return errorDialog(context, "Map cells: $e");
          },
        ).then((_) {
          _dialogOpen = false;
        });
      }
    }
  }

  void animatedUpdate(LatLng from, LatLng to, Duration duration) {
    _animationController.stop();
    _animationController.duration = duration;

    final latTween = Tween(begin: from.latitude, end: to.latitude);
    final lngTween = Tween(begin: from.longitude, end: to.longitude);

    late VoidCallback listener;

    listener = () {
      if (mounted) {
        _mapController.move(
          LatLng(
            latTween.evaluate(_animationController),
            lngTween.evaluate(_animationController),
          ),
          _mapController.camera.zoom,
        );
      }
    };

    _animationController.addListener(listener);

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _animationController.removeListener(listener);
      }
    });
  }

  void liveRecordDataPoller() {
    if (_liveRecordTimer != null) return;
    _liveRecordTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (!mounted) return;

      if (recordingActionNotifier.value && _activeReplayData == null) {
        try {
          final jsonStr = await platform.invokeMethod("getLiveRecording");
          if (jsonStr != null) {
            final Map<String, dynamic> parsedJson = json.decode(jsonStr);
            final List<dynamic> recordsList = parsedJson["records"] ?? [];

            setState(() {
              _liveRecords = recordsList
                  .whereType<Map<String, dynamic>>()
                  .map((item) => Record.fromJson(item))
                  .toList();
            });
          }
        } catch (e) {
          if (!_dialogOpen && mounted) {
            _dialogOpen = true;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return errorDialog(context, "Map live recording: $e");
              },
            ).then((_) {
              _dialogOpen = false;
            });
          }
        }
      }
    });
  }

  void _onTowerSettingsChanged() {
    if (!widget.databaseCellsInMapNotifier.value ||
        !widget.externalDatabaseNotifier.value) {
      _cellTowersNotifier.value = [];
      _cachedBounds = null;
      _lastQueryZoom = null;
    } else if (_isMapReady) {
      checkAndLoadTowers(_mapController.camera.visibleBounds);
    }
  }

  void checkAndLoadTowers(LatLngBounds visibleBounds) async {
    if (_towerQueryInProgress ||
        !widget.externalDatabaseNotifier.value ||
        !widget.databaseCellsInMapNotifier.value) {
      return;
    }
    _towerQueryInProgress = true;

    try {
      if (_lastPlmn.isEmpty) return;

      final double currentZoom = _mapController.camera.zoom;
      final bool zoomChanged =
          _lastQueryZoom == null || (currentZoom - _lastQueryZoom!).abs() > 0.5;

      if (!zoomChanged &&
          _cachedBounds != null &&
          visibleBounds.southWest.latitude >=
              _cachedBounds!.southWest.latitude &&
          visibleBounds.northEast.latitude <=
              _cachedBounds!.northEast.latitude &&
          visibleBounds.southWest.longitude >=
              _cachedBounds!.southWest.longitude &&
          visibleBounds.northEast.longitude <=
              _cachedBounds!.northEast.longitude) {
        return;
      }

      const double spatialPadding = 0.03;
      final double minLat = visibleBounds.southWest.latitude - spatialPadding;
      final double maxLat = visibleBounds.northEast.latitude + spatialPadding;
      final double minLng = visibleBounds.southWest.longitude - spatialPadding;
      final double maxLng = visibleBounds.northEast.longitude + spatialPadding;

      int cellsLimit = 1000;
      if (currentZoom < 10) {
        cellsLimit = 1500;
      } else if (currentZoom >= 10 && currentZoom < 13) {
        cellsLimit = 1000;
      } else if (currentZoom >= 13 && currentZoom < 15) {
        cellsLimit = 800;
      } else {
        cellsLimit = 700;
      }

      final towers = await CellDatabase.fetchMapCellTowers(
        _lastPlmn,
        minLat,
        maxLat,
        minLng,
        maxLng,
        cellsLimit,
      );

      _cachedBounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _lastQueryZoom = currentZoom;

      if (!listEquals(towers, _cellTowersNotifier.value)) {
        _cellTowersNotifier.value = towers;
      }
    } catch (e) {
    } finally {
      _towerQueryInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ValueListenableBuilder(
          valueListenable: _mapLoadingNotifier,
          builder: (context, isLoading, _) {
            return isLoading
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4);
          },
        ),
        Expanded(
          child: Stack(
            children: [
              LiveMap(
                mapController: _mapController,
                currentLocation: _currentLocation,
                selectedRecord: _selectedRecord,
                recordingActive: recordingActionNotifier.value,
                liveRecords: _liveRecords,
                activeReplayData: _activeReplayData,
                followUser: _follow,
                sharedPreferences: sharedPreferences,
                cellTowersNotifier: _cellTowersNotifier,
                onPositionChanged: (camera) {
                  checkAndLoadTowers(camera.visibleBounds);
                },
                onMarkerTap: (record) {
                  setState(() {
                    _selectedRecord = record;
                    _follow = false;
                  });

                  animatedUpdate(
                    _mapController.camera.center,
                    LatLng(record.lat, record.lon),
                    const Duration(milliseconds: 500),
                  );
                },
                onMapInteraction: (shouldUnfollow) {
                  if (shouldUnfollow && _follow) {
                    setState(() => _follow = false);
                  }
                },
                onMapReady: () {
                  _isMapReady = true;
                  _mapLoadingNotifier.value = false;
                  checkAndLoadTowers(_mapController.camera.visibleBounds);
                },
                onMapLoading: (loading) {
                  if (loading) {
                    _mapLoadingDebounce ??= Timer(
                      const Duration(milliseconds: 150),
                      () {
                        _mapLoadingNotifier.value = true;
                        _mapLoadingDebounce = null;
                      },
                    );
                  } else {
                    _mapLoadingDebounce?.cancel();
                    _mapLoadingDebounce = null;
                    _mapLoadingNotifier.value = false;
                  }
                },
                onClearSelection: () => setState(() => _selectedRecord = null),
                onTowerTap: (LatLng towerLatLng) {
                  setState(() {
                    _follow = false;
                  });

                  animatedUpdate(
                    _mapController.camera.center,
                    towerLatLng,
                    const Duration(milliseconds: 500),
                  );
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapOverlay(
                      titlesNotifier: _displayTitlesNotifier,
                      valuesNotifier: _displayValuesNotifier,
                    ),
                    RecordCard(
                      selectedRecord: _selectedRecord,
                      liveRecords: _liveRecords,
                      activeReplayData: _activeReplayData,
                      onClose: () => setState(() => _selectedRecord = null),
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

  void startCellTimer() {
    updateCellInfo();

    _cellTimer = Timer.periodic(Duration(seconds: _updateInterval), (
      timer,
    ) async {
      if (mounted) updateCellInfo();
    });
  }

  void restartTimer() {
    if (_cellTimer == null) return;

    _cellTimer?.cancel();
    startCellTimer();
  }
}
