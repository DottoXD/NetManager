import 'package:material_ui/material_ui.dart';
import 'package:netmanager/types/graph/graph_point.dart';

class SignalAreaChart extends StatelessWidget {
  final String label;
  final String value;
  final List<GraphPoint> graphPoints;
  final int dataRetentionSeconds;
  final Color color;
  final bool showTrend;
  final bool trendUp;
  final Color trendColor;
  final VoidCallback? onTap;

  const SignalAreaChart({
    super.key,
    required this.label,
    required this.value,
    required this.graphPoints,
    required this.dataRetentionSeconds,
    required this.color,
    required this.showTrend,
    required this.trendUp,
    required this.trendColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (showTrend)
                        Icon(
                          trendUp
                              ? Icons.arrow_drop_up_outlined
                              : Icons.arrow_drop_down_outlined,
                          size: 18,
                          color: trendColor,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 90,
                width: double.infinity,
                child: CustomPaint(
                  painter: _AreaChartPainter(
                    graphPoints: graphPoints,
                    dataRetentionSeconds: dataRetentionSeconds,
                    lineColor: color,
                    gridColor: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<GraphPoint> graphPoints;
  final int dataRetentionSeconds;
  final Color lineColor;
  final Color gridColor;

  _AreaChartPainter({
    required this.graphPoints,
    required this.dataRetentionSeconds,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    if (graphPoints.isEmpty) return;

    final DateTime now = DateTime.now();
    final DateTime windowStart = now.subtract(
      Duration(seconds: dataRetentionSeconds),
    );

    double minValue = graphPoints.first.value;
    double maxValue = graphPoints.first.value;
    for (final GraphPoint p in graphPoints) {
      if (p.value < minValue) minValue = p.value;
      if (p.value > maxValue) maxValue = p.value;
    }

    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final double pad = (maxValue - minValue) * 0.15;
    minValue -= pad;
    maxValue += pad;

    final int totalMs = now
        .difference(windowStart)
        .inMilliseconds
        .clamp(1, 1 << 31);

    double xFor(DateTime t) {
      final int elapsed = t.difference(windowStart).inMilliseconds;
      return (elapsed / totalMs) * size.width;
    }

    double yFor(double value) {
      final double ratio = (value - minValue) / (maxValue - minValue);
      return size.height - (ratio * size.height);
    }

    final Path linePath = Path();
    final Path fillPath = Path();

    for (int i = 0; i < graphPoints.length; i++) {
      final double x = xFor(graphPoints[i].time).clamp(0.0, size.width);
      final double y = yFor(graphPoints[i].value).clamp(0.0, size.height);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final double lastX = xFor(graphPoints.last.time).clamp(0.0, size.width);
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.fill;

    const double spacing = 11.0;
    const double dotRadius = 0.9;

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.graphPoints != graphPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dataRetentionSeconds != dataRetentionSeconds ||
        oldDelegate.gridColor != gridColor;
  }
}
