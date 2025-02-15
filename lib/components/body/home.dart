
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeBody extends StatefulWidget {
  const HomeBody(this.platform, this.sharedPreferences, { super.key });
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late MethodChannel platform;
  late Timer timer;
  late SharedPreferences sharedPreferences;
  Widget _progressIndicator = LinearProgressIndicator();

  double cardWidth = 185;
  double cardHeight = 150;

  int _cellid = 0;
  int _earfcn = 0;
  int _pci = 0;
  int _tac = 0;
  int _bw = 0;
  //Array _bands =;
  int _rsrp = 0;
  int _ta = 0;
  int _dbm = 0;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    timer = Timer.periodic(Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3), (Timer t) => update());
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void update() {
    try {
      () async {
        final dataList = (await platform.invokeMethod('getNetworkData')).cast<List<dynamic>>();
    dataList.forEach((cellInfoData) {
    final cellInfoMap = Map<String, dynamic>.from(cellInfoData);
    final cellInfo = NetworkData.fromMap(cellInfoMap);

    if (cellInfo.type == 'LTE') {
    _cellid = cellInfo.cellId as int;
    _earfcn = cellInfo.earfcn as int;
    _pci = cellInfo.pci as int;
    _tac = cellInfo.tac as int;
    _bw = cellInfo.bw as int;
    //_bands = cellInfo.bands;
    _rsrp = cellInfo.rsrp as int;
    _ta = cellInfo.ta as int;
    _dbm = cellInfo.dbm as int;
    }
    });

    setState(() {
    _cellid;
    _earfcn;
    _pci;
    _tac;
    _bw;
    //_bands;
    _rsrp;
    _ta;
    _dbm;

    _progressIndicator = Container();
    });
    } ();
    } on PlatformException catch (_) {
    //super error, handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: <Widget>[
            Row(
                children: [
                  Expanded(
                      child: _progressIndicator
                  ),
                ]
            ),
            Container(
                margin: EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 10
                ),
                child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Text("cellid $_cellid earfcn $_earfcn pci $_pci \ntac $_tac bw $_bw bands  \nrsrp $_rsrp ta $_ta dbm $_dbm")
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth * 2 + 10,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                        "Cell Tower",
                                        style: TextStyle(
                                            fontSize: 16
                                        )
                                    ),
                                    SizedBox(height: 3),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.network_cell_sharp, size: 50),
                                        Text(
                                          "$_cellid",
                                          style: TextStyle(
                                              fontSize: 24
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Text("cellid $_cellid earfcn $_earfcn pci $_pci \ntac $_tac bw $_bw bands  \nrsrp $_rsrp ta $_ta dbm $_dbm")
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              right: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("LTE Band"),
                                      subtitle: Text("$_bw"),
                                    )
                                  ],
                                )
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              left: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("SNR"),
                                      subtitle: Text("${_rsrp}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Text("cellid $_cellid earfcn $_earfcn pci $_pci \ntac $_tac bw $_bw bands  \nrsrp $_rsrp ta $_ta dbm $_dbm")
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              right: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("LTE RSRP"),
                                      subtitle: Text("${_rsrp}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              left: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("LTE SNR"),
                                      subtitle: Text("${_rsrp}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Text("cellid $_cellid earfcn $_earfcn pci $_pci \ntac $_tac bw $_bw bands  \nrsrp $_rsrp ta $_ta dbm $_dbm")
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              right: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("LTE CID"),
                                      subtitle: Text("${_cellid}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              left: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("NR Band"),
                                      subtitle: Text("${_rsrp}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Text("cellid $_cellid earfcn $_earfcn pci $_pci \ntac $_tac bw $_bw bands  \nrsrp $_rsrp ta $_ta dbm $_dbm")
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              right: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("NR RSRP"),
                                      subtitle: Text("${_dbm}dBm"),
                                    )
                                  ],
                                )
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            margin: EdgeInsets.only(
                              bottom: 10,
                              left: 5,
                            ),
                            color: Theme.of(context).colorScheme.onSecondary,
                            child: Container(
                                width: cardWidth,
                                height: cardHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text("TA"),
                                      subtitle: Text("$_ta"),

                                    )
                                  ],
                                )
                            ),
                          ),
                        ],
                      )
                    ]
                )
            )
          ],
        )
    );
  }
}

class NetworkData {
  //General data
  String cellId;
  String type;
  bool registered;

  //LTE specific data
  String? earfcn;
  String? pci;
  String? tac;
  String? bw;
  String? bands;
  String? rsrp;
  String? rsrq;
  String? rssi;
  String? snr;
  String? ta;
  String? dbm;

  //GSM specific data
  String? arfcn;
  String? bsic;
  String? lac;

  //WCDMA specific data
  String? uarfcn;
  String? psc;
  String? ecno;

  NetworkData({
    required this.cellId,
    required this.type,
    required this.registered,
    this.earfcn,
    this.pci,
    this.tac,
    this.bw,
    this.bands,
    this.rsrp,
    this.rsrq,
    this.rssi,
    this.snr,
    this.ta,
    this.dbm,
    this.arfcn,
    this.bsic,
    this.lac,
    this.uarfcn,
    this.psc,
    this.ecno,
  });

  factory NetworkData.fromMap(Map<String, dynamic> map) {
    return NetworkData(
      cellId: map['cellId'] ?? '',
      type: map['type'] ?? '',
      registered: map['registered'] ?? false,
      earfcn: map['earfcn'],
      pci: map['pci'],
      tac: map['tac'],
      bw: map['bw'],
      bands: map['bands'],
      rsrp: map['rsrp'],
      rsrq: map['rsrq'],
      rssi: map['rssi'],
      snr: map['snr'],
      ta: map['ta'],
      dbm: map['dbm'],
      arfcn: map['arfcn'],
      bsic: map['bsic'],
      lac: map['lac'],
      uarfcn: map['uarfcn'],
      psc: map['psc'],
      ecno: map['ecno'],
    );
  }
}