import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:netmanager/components/base/body/map/widgets/live_map.dart';
import 'package:netmanager/components/base/body/map/widgets/record_card.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/record_modal.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/components/base/body/map/widgets/map_overlay.dart';
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
  final MapController _mapController = MapController();
  late AnimationController _animationController;

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

  final ValueNotifier<bool> mapLoadingNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);

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
    _mapController.dispose();
    _animationController.dispose();

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

      mapLoadingNotifier.value = false;
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
        ValueListenableBuilder(
          valueListenable: mapLoadingNotifier,
          builder: (context, isLoading, _) {
            return isLoading
                ? const LinearProgressIndicator()
                : const SizedBox.shrink();
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
                onMapReady: () => mapLoadingNotifier.value = false,
                onMapLoading: (loading) => mapLoadingNotifier.value = loading,
                onClearSelection: () => setState(() => _selectedRecord = null),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapOverlay(
                      titlesNotifier: displayTitlesNotifier,
                      valuesNotifier: displayValuesNotifier,
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
