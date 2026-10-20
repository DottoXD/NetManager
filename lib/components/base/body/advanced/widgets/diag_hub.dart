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

  static const List<String> features = ["lte_serving_cell", "lte_bearers"];
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

  Map<String, dynamic>? servingMeasFor(int slot) =>
      _servingMeasBySlot[slot] ?? _servingMeasBySlot[null];

  Map<String, dynamic>? cellInfoFor(int slot) =>
      _cellInfoBySlot[slot] ?? _cellInfoBySlot[null];

  List<Map<String, dynamic>> bearersFor(int slot) {
    final merged = {...?_bearersBySlot[null], ...?_bearersBySlot[slot]};
    final ids = merged.keys.toList()..sort();

    return [for (final id in ids) merged[id]!];
  }

  void acquire() {
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

    await _connectAndRequest();
  }

  Future<void> _connectAndRequest() async {
    try {
      await _method.invokeMethod("connect");
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
    _bearersBySlot.clear();
  }

  Future<void> reconnect() async {
    connState.value = DiagConnState.connecting;
    await _connectAndRequest();
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
        final s = data as Map<String, dynamic>?;
        status.value = s;
        if (s?["connected"] == true) connState.value = DiagConnState.connected;
        pushLog(
          "STATUS",
          "vendor=${s?["vendor"]} transport=${s?["transport"]} "
              "supported=${s?["supported"]} active=${s?["active"]}",
        );
        break;
      case "lteServingMeas":
        connState.value = DiagConnState.connected;
        final m = data as Map<String, dynamic>?;
        if (m != null) _servingMeasBySlot[m["slot"] as int?] = m;
        pushLog(
          "LTE MEAS",
          "earfcn=${m?["earfcn"]} pci=${m?["pci"]} "
              "rsrp=${fmtNum(m?["rsrp_dbm"])} rsrq=${fmtNum(m?["rsrq_db"])} "
              "rssi=${fmtNum(m?["rssi_dbm"])}",
          slot: m?["slot"] as int?,
        );
        _markDirty(data: true);
        break;
      case "lteCellInfo":
        connState.value = DiagConnState.connected;
        final c = data as Map<String, dynamic>?;
        if (c != null) _cellInfoBySlot[c["slot"] as int?] = c;
        pushLog(
          "CELL INFO",
          "earfcn=${c?["earfcn"]} pci=${c?["pci"]} "
              "bw=${fmtNum(c?["dl_bandwidth_mhz"])}MHz",
          slot: c?["slot"] as int?,
        );
        _markDirty(data: true);
        break;
      case "lteBearer":
        connState.value = DiagConnState.connected;
        final b = data as Map<String, dynamic>?;
        if (b != null) {
          final id = b["eps_bearer_id"] as int;
          (_bearersBySlot[b["slot"] as int?] ??= {})[id] = b;
          pushLog(
            "BEARER",
            "${b["dedicated"] == true ? "dedicated" : "default"} id=$id "
                "qci=${b["qci"] ?? "-"} apn=${b["apn"] ?? "-"} "
                "ambr=${fmtRate(b["apn_ambr_dl_kbps"])}/${fmtRate(b["apn_ambr_ul_kbps"])}",
            slot: b["slot"] as int?,
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
