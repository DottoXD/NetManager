import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/components/base/body/home/widgets/cell_section.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/events/event_types.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:netmanager/types/events/netmanager_event.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/utils/gen_color.dart';

class RecordSheet extends StatelessWidget {
  const RecordSheet({
    super.key,
    required this.record,
    this.matchedEvents = const [],
  });

  final Record record;
  final List<NetmanagerEvent> matchedEvents;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    final sim = record.simData;
    final formatter = DateFormat("HH:mm:ss");
    final Color genColor = getGenColor(context, sim?.networkGen ?? 0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (sim != null)
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: genColor.withValues(alpha: 0.15),
                          child: Text(
                            "${sim.networkGen}G",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: genColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        sim?.operator ?? appLocalizations.unknown,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (matchedEvents.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            appLocalizations.eventLogs,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontSize: 18),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: matchedEvents.map((event) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                "${formatEventName(event.eventType.name)} (${formatter.format(event.dateTime.toLocal())})",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        event.oldValue,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 14,
                                              height: 1.1,
                                            ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Icon(
                                          Icons.arrow_right_outlined,
                                          size: 18,
                                        ),
                                      ),
                                      Text(
                                        event.newValue,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 14,
                                              height: 1.1,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (event is MobileNetmanagerEvent) ...[
                                    Text(
                                      "SIM ${event.simSlot + 1} ${event.network.trim().isNotEmpty ? "(${event.network})" : "(${appLocalizations.unknown})"}",
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (sim != null && sim.activeCells.isNotEmpty)
                      CellSection(
                        title: appLocalizations.homeActiveCells,
                        cells: sim.activeCells,
                        isActive: true,
                        descriptions: const {},
                        guessedCids: const {},
                      ),
                    if (sim != null && sim.neighborCells.isNotEmpty)
                      CellSection(
                        title: appLocalizations.homeNeighborCells,
                        cells: sim.neighborCells,
                        isActive: false,
                        descriptions: const {},
                        guessedCids: const {},
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
