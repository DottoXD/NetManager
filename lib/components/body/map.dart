import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/utils/map_tile_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class MapBody extends StatefulWidget {
  const MapBody(this.platform, this.sharedPreferences, {super.key});
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<MapBody> {
  late Widget _map = Row();
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  final MapController mapController = MapController();
  Widget _progressIndicator = LinearProgressIndicator();

  Timer? _timer;
  Timer? _animationTimer;
  LatLng? _currentLocation;

  bool _zooming = false;
  bool _dialogOpen = false;
  bool disposed = false;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setLocation(true);
      updateLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationTimer?.cancel();

    super.dispose();
    disposed = true;
  }

  Future<void> setLocation(bool init) async {
    try {
      final String jsonString = await platform.invokeMethod("getLocation");
      final List<dynamic> coordinates = json.decode(jsonString);

      final lat = coordinates[0] as double;
      final lon = coordinates[1] as double;

      LatLng? oldLocation;
      if (_currentLocation != null) {
        oldLocation = _currentLocation!;
      }

      setState(() {
        _currentLocation = LatLng(lat, lon);
      });

      if (init) {
        mapController.move(_currentLocation!, mapController.camera.zoom);
      } else {
        if (oldLocation == null) {
          return;
        }

        animatedUpdate(
          oldLocation,
          _currentLocation!,
          Duration(milliseconds: 500),
        );
      }
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

  void updateLocation() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await setLocation(false);
    });
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
        Row(children: [Expanded(child: _progressIndicator)]),
        Expanded(child: getMap(context)),
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
        maxZoom: 15.0,
        initialZoom: 13.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onMapReady: () {
          setState(() {
            _progressIndicator = Container();
          });
        },
        onMapEvent: (p0) {
          setState(() {
            _progressIndicator = Container();
          });
        },
        onPositionChanged: (camera, hasGesture) {
          if (_zooming) return;

          final double roundedZoom = mapController.camera.zoom.roundToDouble();

          if ((roundedZoom - mapController.camera.zoom).abs() > 0.01) {
            _zooming = true;
            mapController.move(mapController.camera.center, roundedZoom);
            Future.delayed(Duration(milliseconds: 50), () {
              _zooming = false;
            });
          }

          setState(() {
            _progressIndicator = LinearProgressIndicator();
          });
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
                    color: Colors.blue,
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
}
