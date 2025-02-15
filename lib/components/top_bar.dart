import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar(this.platform, { super.key });
  final MethodChannel platform;

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  late MethodChannel platform;

  String _title = "NetManager is loading...";
  String _carrier = "NetManager";
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;

    Timer.periodic(Duration(seconds: 1), (Timer t) => update());
  }

  void update() {
    try {
      () async {
        _carrier = (await platform.invokeMethod<String>('getCarrier'))!;
    _gen = await platform.invokeMethod<int>('getNetworkGen') as int;
    } ();

    if(_gen > 0) {
    _title = "${"$_carrier $_gen"}G";
    } else {
    _title = "No service";
    }

    setState(() {
    _title;
    });
    } on PlatformException catch (_) {
    //super error, handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_title),
      actions: [
        IconButton(
            onPressed: update,
            icon: Icon(Icons.info)
        ),
        IconButton(
            onPressed: update,
            icon: Icon(Icons.menu)
        )
      ],
    );
  }
}