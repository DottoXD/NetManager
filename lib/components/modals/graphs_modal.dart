import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/graph/graph_metric.dart';
import 'package:netmanager/utils/graph_utils.dart';
import 'package:netmanager/components/base/body/home/widgets/signal_area_chart.dart';

class GraphsModal extends StatelessWidget {
  final Listenable graphsUpdateNotifier;
  final int dataRetentionSeconds;
  final List<GraphMetric> Function() metricsBuilder;

  const GraphsModal({
    super.key,
    required this.graphsUpdateNotifier,
    required this.dataRetentionSeconds,
    required this.metricsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: graphsUpdateNotifier,
        builder: (context, _) {
          final List<GraphMetric> metrics = metricsBuilder();

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: metrics.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            appLocalizations.homeGraphsEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          shrinkWrap: true,
                          children: _buildRows(theme, metrics),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRows(ThemeData theme, List<GraphMetric> metrics) {
    final List<Widget> rows = [];

    for (int i = 0; i < metrics.length; i += 2) {
      final GraphMetric left = metrics[i];
      final GraphMetric? right = (i + 1 < metrics.length)
          ? metrics[i + 1]
          : null;

      if (right == null) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: _chartFor(theme, left),
          ),
        );
        continue;
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _chartFor(theme, left),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _chartFor(theme, right),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _chartFor(ThemeData theme, GraphMetric metric) {
    return Builder(
      builder: (context) {
        final double latestValue = metric.history.isNotEmpty
            ? metric.history.last.value
            : 0;
        final ValueQuality valueQuality = classifyQuality(
          metric.label,
          latestValue,
        );
        final Color color = colorForQuality(context, valueQuality);

        bool? trendPositive;
        Color trendColor = theme.colorScheme.onSurfaceVariant;

        if (metric.history.length >= 2) {
          final double previousValue =
              metric.history[metric.history.length - 2].value;
          final double lastValue = metric.history.last.value;

          if (lastValue != previousValue) {
            trendPositive = lastValue > previousValue;

            final ValueQuality prevQuality = classifyQuality(
              metric.label,
              previousValue,
            );

            if (valueQuality.index < prevQuality.index) {
              trendColor = theme.colorScheme.primary;
            } else if (valueQuality.index > prevQuality.index) {
              trendColor = theme.colorScheme.error;
            }
          }
        }

        return SignalAreaChart(
          label: metric.label,
          value: metric.displayValue,
          graphPoints: metric.history,
          dataRetentionSeconds: dataRetentionSeconds,
          color: color,
          showTrend: trendPositive != null,
          trendUp: trendPositive ?? true,
          trendColor: trendColor,
        );
      },
    );
  }
}
