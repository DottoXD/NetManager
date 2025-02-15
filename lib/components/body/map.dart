import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapBody extends StatefulWidget {
  const MapBody(this.platform, { super.key });
  final MethodChannel platform;

  @override
  State<MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<MapBody> {
  late Widget _map = Row();
  late MethodChannel platform;
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
          Row(
              children: [
                Expanded(
                    child: _progressIndicator
                ),
              ]
          ),
          SizedBox(
              height: 300,
              child: _map
          )
        ]
    );
  }

  void getMap() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if(!disposed && context.mounted) {
      setState(() {
        _progressIndicator = LinearProgressIndicator();
        _map = FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(position.latitude, position.longitude),
              initialZoom: 9.2,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "me.dotto.netmanager",
              ),
            ]
        );
        _progressIndicator = Text("");
      });
    }
  }
}