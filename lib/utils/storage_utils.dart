import 'package:flutter/services.dart';
import 'package:netmanager/types/storage/storage_directory.dart';
import 'package:netmanager/types/storage/storage_file.dart';

class StorageUtils {
  static const MethodChannel _platform = MethodChannel(
    "pw.dotto.netmanager/storage",
  );

  static Future<StorageFile?> pickFile(List<String> extensions) async {
    final Map<dynamic, dynamic>? selected = await _platform
        .invokeMethod<Map<dynamic, dynamic>>("pickFile", {
          "extensions": extensions,
        });

    if (selected == null) return null;

    return StorageFile(
      name: selected["name"] as String,
      path: selected["path"] as String,
    );
  }

  static Future<StorageDirectory?> pickDirectory() async {
    final Map<dynamic, dynamic>? selected = await _platform
        .invokeMethod<Map<dynamic, dynamic>>("pickDirectory");

    if (selected == null) return null;

    return StorageDirectory(
      name: selected["name"] as String,
      uri: selected["uri"] as String,
    );
  }

  static Future<bool> saveFile({
    required String name,
    required String path,
    required String mimeType,
  }) async {
    final String? uri = await _platform.invokeMethod<String>("saveFile", {
      "name": name,
      "path": path,
      "mimeType": mimeType,
    });

    return uri != null;
  }

  static Future<void> deleteCachedFile(String path) async {
    await _platform.invokeMethod("deleteCachedFile", {"path": path});
  }

  static Future<int> getPendingRecordingCount() async {
    return await _platform.invokeMethod<int>("getPendingRecordingCount") ?? 0;
  }

  static Future<({int exported, int pending})> retryPendingRecordings({
    String? directoryUri,
  }) async {
    final Map<dynamic, dynamic>? result = await _platform
        .invokeMethod<Map<dynamic, dynamic>>("retryPendingRecordings", {
          "directoryUri": directoryUri,
        });

    return (
      exported: result?["exported"] as int? ?? 0,
      pending: result?["pending"] as int? ?? 0,
    );
  }
}
