import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/modals/record/convert_recording.dart';
import 'package:netmanager/components/modals/record/new_recording.dart';
import 'package:netmanager/components/modals/record/replay_recording.dart';
import 'package:netmanager/types/recording/recorded_data.dart';

enum ExportFormat { kml, csv }

class RecordModal extends StatelessWidget {
  const RecordModal({
    super.key,
    required this.platform,
    required this.recordingActionNotifier,
    required this.onDataLoaded,
    required this.onRecordingStarted,
  });

  final MethodChannel platform;
  final ValueNotifier<bool> recordingActionNotifier;
  final void Function(RecordedData) onDataLoaded;
  final void Function() onRecordingStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NewRecording(
            platform: platform,
            recordingActionNotifier: recordingActionNotifier,
            onRecordingStarted: onRecordingStarted,
          ),
          ReplayRecording(onDataLoaded: onDataLoaded),
          ConvertRecording(platform: platform),
        ],
      ),
    );
  }
}
