import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
  Widget _progressIndicator = LinearProgressIndicator();

  bool disposed = false;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
  }

  @override
  void dispose() {
    super.dispose();
    disposed = true;
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
    /*List<LocationAccuracy> accuracies = [
      LocationAccuracy.reduced,
      LocationAccuracy.low,
      LocationAccuracy.medium,
      LocationAccuracy.high,
    ];

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy:
            accuracies[sharedPreferences.getInt("positionPrecision") ?? 0],
      ),
    );*/

    return FlutterMap(
      options: MapOptions(
        backgroundColor: Theme.of(context).colorScheme.surface,
        initialCenter: LatLng(
          45.464664,
          9.188540,
        ), //to be replaced with the user's position...
        minZoom: 5.0,
        initialZoom: 10.0,
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
        SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }
}
