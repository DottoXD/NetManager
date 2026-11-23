import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DiagConnState { connecting, connected, disconnected, error }

enum DiagLogCode {
  disconnected,
  unknownError,
  stopFailed,
  stopped,
  stopUnconfirmed,
  startRequested,
}

class DiagLogEntry {
  final String type;
  final String message;
  final String lowerMessage;
  final int? slot;
  final String time;
  final DiagLogCode? code;

  DiagLogEntry({
    required this.type,
    required this.message,
    required this.slot,
    required this.time,
    this.code,
  }) : lowerMessage = message.toLowerCase();
}

class DiagHub {
  DiagHub._();
  static final DiagHub instance = DiagHub._();

  static const MethodChannel _method = MethodChannel(
    "pw.dotto.netmanager/diag",
  );
  static const EventChannel _events = EventChannel(
    "pw.dotto.netmanager/diag/events",
  );

  late ValueNotifier<bool> _autoStartNetManagerDiagOnAdvancedModeNotifier;

  static const List<String> features = [
    "lte_serving_cell",
    "lte_bearers",
    "umts_serving_cell",
    "gsm_serving_cell",
  ];
  static const int _maxLogEntries = 500;
  static const Duration _flushDelay = Duration(milliseconds: 150);

  final ValueNotifier<DiagConnState> connState = ValueNotifier(
    DiagConnState.connecting,
  );
  final ValueNotifier<String?> lastError = ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> status = ValueNotifier(null);
  final ValueNotifier<int> dataRevision = ValueNotifier(0);
  final ValueNotifier<int> logRevision = ValueNotifier(0);

  final List<DiagLogEntry> log = [];

  final Map<int?, Map<String, dynamic>> _servingMeasBySlot = {};
  final Map<int?, Map<String, dynamic>> _cellInfoBySlot = {};
  final Map<int?, Map<String, dynamic>> _umtsCellBySlot = {};
  final Map<int?, Map<String, dynamic>> _umtsMeasBySlot = {};
  final Map<int?, Map<String, dynamic>> _gsmCellBySlot = {};
  final Map<int?, Map<String, dynamic>> _gsmMeasBySlot = {};

  final Map<int?, Map<int, Map<String, dynamic>>> _bearersBySlot = {};

  int _refs = 0;
  StreamSubscription<dynamic>? _sub;
  Timer? _flushTimer;
  bool _dataDirty = false;
  bool _logDirty = false;

  List<int> get slotsSeen =>
      ((status.value?["slots_seen"] as List<dynamic>?) ?? const [])
          .whereType<int>()
          .toList();

  bool get modemTagsSlots => slotsSeen.isNotEmpty;

  bool get daemonOutdated => status.value?["outdated"] == true;

  Map<String, dynamic>? servingMeasFor(int slot) =>
      _servingMeasBySlot[slot] ?? _servingMeasBySlot[null];

  Map<String, dynamic>? cellInfoFor(int slot) =>
      _cellInfoBySlot[slot] ?? _cellInfoBySlot[null];

  Map<String, dynamic>? umtsCellFor(int slot) =>
      _umtsCellBySlot[slot] ?? _umtsCellBySlot[null];

  Map<String, dynamic>? umtsMeasFor(int slot) =>
      _umtsMeasBySlot[slot] ?? _umtsMeasBySlot[null];

  Map<String, dynamic>? gsmCellFor(int slot) =>
      _gsmCellBySlot[slot] ?? _gsmCellBySlot[null];

  Map<String, dynamic>? gsmMeasFor(int slot) =>
      _gsmMeasBySlot[slot] ?? _gsmMeasBySlot[null];

  List<Map<String, dynamic>> bearersFor(int slot) {
    final merged = {...?_bearersBySlot[null], ...?_bearersBySlot[slot]};
    final ids = merged.keys.toList()..sort();

    return [for (final id in ids) merged[id]!];
  }

  void acquire({
    required ValueNotifier<bool> autoStartNetManagerDiagOnAdvancedModeNotifier,
  }) {
    _autoStartNetManagerDiagOnAdvancedModeNotifier =
        autoStartNetManagerDiagOnAdvancedModeNotifier;
    if (_refs++ == 0) _start();
  }

  void release() {
    if (_refs == 0) return;
    if (--_refs == 0) _stop();
  }

  void _markDirty({bool data = false, bool logs = false}) {
    _dataDirty = _dataDirty || data;
    _logDirty = _logDirty || logs;
    _flushTimer ??= Timer(_flushDelay, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (_dataDirty) {
      _dataDirty = false;
      dataRevision.value++;
    }
    if (_logDirty) {
      _logDirty = false;
      logRevision.value++;
    }
  }

  Future<void> _start() async {
    connState.value = DiagConnState.connecting;
    lastError.value = null;

    _sub = _events.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object error, StackTrace _) {
        connState.value = DiagConnState.error;
        lastError.value = error.toString();
        pushLog("ERROR", error.toString());
      },
    );

    await _connectAndRequest(automatic: true);
  }

  Future<void> _connectAndRequest({required bool automatic}) async {
    try {
      await _method.invokeMethod("connect", {
        "automatic": automatic,
        "autostart": _autoStartNetManagerDiagOnAdvancedModeNotifier.value,
      });
      await _method.invokeMethod("requestFeatures", {
        "features": features,
        "wanted": true,
      });
    } on PlatformException catch (e) {
      lastError.value = e.message;
      connState.value = DiagConnState.error;
    }
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _dataDirty = false;
    _logDirty = false;

    try {
      await _method.invokeMethod("requestFeatures", {
        "features": features,
        "wanted": false,
      });
    } on PlatformException catch (_) {}
    _servingMeasBySlot.clear();
    _cellInfoBySlot.clear();
    _umtsCellBySlot.clear();
    _umtsMeasBySlot.clear();
    _gsmCellBySlot.clear();
    _gsmMeasBySlot.clear();
    _bearersBySlot.clear();
  }

  Future<void> reconnect() async {
    connState.value = DiagConnState.connecting;
    lastError.value = null;
    await _connectAndRequest(automatic: false);
  }

  void _onEvent(dynamic raw) {
    if (raw is! String) return;

    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final String? type = msg["type"] as String?;
    final dynamic data = msg["data"];

    switch (type) {
      case "status":
        final stat = data as Map<String, dynamic>?;

        status.value = stat;
        if (stat?["connected"] == true) {
          connState.value = DiagConnState.connected;
        }

        pushLog(
          "STATUS",
          "vendor=${stat?["vendor"]} transport=${stat?["transport"]} "
              "supported=${stat?["supported"]} active=${stat?["active"]} "
              "protocol=${stat?["protocol"] ?? 0} version=${stat?["version"] ?? "-"}",
        );
        break;
      case "lteServingMeas":
        connState.value = DiagConnState.connected;
        final lteServingMeas = data as Map<String, dynamic>?;

        if (lteServingMeas != null) {
          _servingMeasBySlot[lteServingMeas["slot"] as int?] = lteServingMeas;
        }

        pushLog(
          "LTE MEAS",
          "earfcn=${lteServingMeas?["earfcn"]} pci=${lteServingMeas?["pci"]} "
              "rsrp=${fmtNum(lteServingMeas?["rsrp_dbm"])} rsrq=${fmtNum(lteServingMeas?["rsrq_db"])} "
              "rssi=${fmtNum(lteServingMeas?["rssi_dbm"])}",
          slot: lteServingMeas?["slot"] as int?,
        );
        _markDirty(data: true);
        break;
      case "lteCellInfo":
        connState.value = DiagConnState.connected;
        final lteCell = data as Map<String, dynamic>?;

        if (lteCell != null) _cellInfoBySlot[lteCell["slot"] as int?] = lteCell;
        pushLog(
          "CELL INFO",
          "earfcn=${lteCell?["earfcn"]} pci=${lteCell?["pci"]} "
              "bw=${fmtNum(lteCell?["dl_bandwidth_mhz"])}MHz "
              "antennas=${lteCell?["num_antennas"] ?? "-"}",
          slot: lteCell?["slot"] as int?,
        );

        _markDirty(data: true);
        break;
      case "umtsCellInfo":
        connState.value = DiagConnState.connected;
        final umtsCell = data as Map<String, dynamic>?;

        if (umtsCell != null) {
          _umtsCellBySlot[umtsCell["slot"] as int?] = umtsCell;
        }

        pushLog(
          "UMTS CELL",
          "uarfcn=${umtsCell?["uarfcn_dl"]} psc=${umtsCell?["psc"]} rnc=${umtsCell?["rnc"]} "
              "cell=${umtsCell?["cell_id"]} lac=${umtsCell?["lac"]} "
              "plmn=${umtsCell?["mcc"]}-${umtsCell?["mnc"]}",
          slot: umtsCell?["slot"] as int?,
        );

        _markDirty(data: true);
        break;
      case "umtsServingMeas":
        connState.value = DiagConnState.connected;
        final umtsServingMeas = data as Map<String, dynamic>?;

        if (umtsServingMeas != null) {
          _umtsMeasBySlot[umtsServingMeas["slot"] as int?] = umtsServingMeas;
        }

        pushLog(
          "UMTS MEAS",
          "uarfcn=${umtsServingMeas?["uarfcn"]} psc=${umtsServingMeas?["psc"]} "
              "rscp=${umtsServingMeas?["rscp_dbm"]} ecio=${umtsServingMeas?["ecio_db"]}",
          slot: umtsServingMeas?["slot"] as int?,
        );

        _markDirty(data: true);
        break;
      case "gsmCellInfo":
        connState.value = DiagConnState.connected;
        final gsmCell = data as Map<String, dynamic>?;

        if (gsmCell != null) _gsmCellBySlot[gsmCell["slot"] as int?] = gsmCell;
        pushLog(
          "GSM CELL",
          "arfcn=${gsmCell?["arfcn"]} bsic=${gsmCell?["bsic"]} cell=${gsmCell?["cell_id"]} "
              "lac=${gsmCell?["lac"]} plmn=${gsmCell?["mcc"]}${gsmCell?["mnc"]}",
          slot: gsmCell?["slot"] as int?,
        );

        _markDirty(data: true);
        break;
      case "gsmServingMeas":
        connState.value = DiagConnState.connected;
        final gsmServingMeas = data as Map<String, dynamic>?;

        if (gsmServingMeas != null) {
          _gsmMeasBySlot[gsmServingMeas["slot"] as int?] = gsmServingMeas;
        }

        pushLog(
          "GSM MEAS",
          "rssi=${fmtNum(gsmServingMeas?["rssi_dbm"])}",
          slot: gsmServingMeas?["slot"] as int?,
        );

        _markDirty(data: true);
        break;
      case "lteBearer":
        connState.value = DiagConnState.connected;
        final bearer = data as Map<String, dynamic>?;

        if (bearer != null) {
          final id = bearer["eps_bearer_id"] as int;

          (_bearersBySlot[bearer["slot"] as int?] ??= {})[id] = bearer;
          pushLog(
            "BEARER",
            "${bearer["dedicated"] == true ? "dedicated" : "default"} id=$id "
                "qci=${bearer["qci"] ?? "-"} apn=${bearer["apn"] ?? "-"} "
                "ambr=${fmtRate(bearer["apn_ambr_dl_kbps"])}/${fmtRate(bearer["apn_ambr_ul_kbps"])}",
            slot: bearer["slot"] as int?,
          );

          _markDirty(data: true);
        }
        break;
      case "error":
        final err = data as String?;

        lastError.value = err;
        if (err == null) {
          pushLog("ERROR", "", code: DiagLogCode.unknownError);
        } else {
          pushLog("ERROR", err);
        }
        break;
      case "disconnected":
        connState.value = DiagConnState.disconnected;
        _servingMeasBySlot.clear();
        _cellInfoBySlot.clear();
        _umtsCellBySlot.clear();
        _umtsMeasBySlot.clear();
        _gsmCellBySlot.clear();
        _gsmMeasBySlot.clear();
        _bearersBySlot.clear();
        pushLog("DISCONNECT", "", code: DiagLogCode.disconnected);

        _markDirty(data: true);
        break;
    }
  }

  void pushLog(String type, String message, {int? slot, DiagLogCode? code}) {
    final now = DateTime.now();
    String padNumber(int n) => n.toString().padLeft(2, "0");

    log.insert(
      0,
      DiagLogEntry(
        type: type,
        message: message,
        slot: slot,
        code: code,
        time:
            "${padNumber(now.hour)}:${padNumber(now.minute)}:${padNumber(now.second)}",
      ),
    );

    if (log.length > _maxLogEntries) {
      log.removeRange(_maxLogEntries, log.length);
    }

    _markDirty(logs: true);
  }

  static String fmtRate(dynamic kbps) {
    if (kbps is! num) return "-";
    if (kbps >= 1000000) return "${(kbps / 1000000).toStringAsFixed(2)} Gbps";
    if (kbps >= 1000) {
      return "${(kbps / 1000).toStringAsFixed(kbps % 1000 == 0 ? 0 : 1)} Mbps";
    }

    return "$kbps Kbps";
  }

  static String fmtNum(dynamic n) {
    if (n == null) return "-";
    if (n is num) return n.toStringAsFixed(2);

    return n.toString();
  }
}
