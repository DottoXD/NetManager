import 'package:netmanager/types/graph/graph_point.dart';

class GraphMetric {
  final String label;
  final String displayValue;
  final List<GraphPoint> history;

  const GraphMetric({
    required this.label,
    required this.displayValue,
    required this.history,
  });
}
