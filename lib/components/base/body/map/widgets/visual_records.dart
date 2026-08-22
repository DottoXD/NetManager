import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:netmanager/components/base/body/map/widgets/record_marker.dart';
import 'package:netmanager/types/recording/record.dart';

class VisualRecords extends StatelessWidget {
  final List<Record> visualPoints;
  final Record? selectedRecord;
  final ValueChanged<Record> onMarkerTap;

  const VisualRecords({
    super.key,
    required this.visualPoints,
    required this.selectedRecord,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: visualPoints.map((record) {
        final isSelected =
            selectedRecord != null &&
            selectedRecord!.dateTime == record.dateTime;

        return Marker(
          point: LatLng(record.lat, record.lon),
          width: isSelected ? 20 : 14,
          height: isSelected ? 20 : 14,
          child: RecordMarker(
            record: record,
            isSelected: isSelected,
            onMarkerTap: onMarkerTap,
          ),
        );
      }).toList(),
    );
  }
}
