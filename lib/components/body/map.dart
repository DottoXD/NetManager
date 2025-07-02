import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
    getMap();
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
        SizedBox(height: 300, child: _map),
      ],
    );
  }

  void getMap() async {
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

    if (!disposed && context.mounted) {
      setState(() {
        _progressIndicator = LinearProgressIndicator();
        _map = FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              45.464664,
              9.188540,
            ), //to be replaced with the user's position...
            initialZoom: 9.2,
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "pw.dotto.netmanager",
            ),
            SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
          ],
        );
        _progressIndicator = Container();
      });
    }
  }
}
