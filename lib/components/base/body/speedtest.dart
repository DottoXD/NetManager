import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeedtestBody extends StatefulWidget {
  const SpeedtestBody(this.platform, this.sharedPreferences, {super.key});

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<SpeedtestBody> createState() => _SpeedtestBodyState();
}

class _SpeedtestBodyState extends State<SpeedtestBody> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
          
        ],
    );
  }
}
