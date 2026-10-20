import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_widgets.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class BearersPage extends StatelessWidget {
  final ValueListenable<int> simSlotNotifier;

  const BearersPage({super.key, required this.simSlotNotifier});

  @override
  Widget build(BuildContext context) {
    final diagHub = DiagHub.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 64),
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([diagHub.connState, diagHub.lastError]),
          builder: (context, _) => DiagBanner(
            state: diagHub.connState.value,
            error: diagHub.lastError.value,
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            diagHub.dataRevision,
            diagHub.connState,
            simSlotNotifier,
          ]),
          builder: (context, _) {
            return _Body(bearers: diagHub.bearersFor(simSlotNotifier.value));
          },
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> bearers;

  const _Body({required this.bearers});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (bearers.isEmpty) {
      return InfoCard(
        title: appLocalizations.advancedModeDataBearers,
        icon: Icons.swap_vert_outlined,
        child: Text(
          appLocalizations.advancedModeBearersWaiting,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < bearers.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _BearerCard(bearer: bearers[i]),
        ],
      ],
    );
  }
}

class _BearerCard extends StatelessWidget {
  final Map<String, dynamic> bearer;

  const _BearerCard({required this.bearer});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final bool dedicated = bearer["dedicated"] == true;
    final int id = bearer["eps_bearer_id"] as int;
    final String? apn = bearer["apn"] as String?;
    final String? pdnType = bearer["pdn_type"] as String?;

    return InfoCard(
      title: dedicated
          ? appLocalizations.advancedModeBearerDedicated(id)
          : appLocalizations.advancedModeBearerDefault(id),
      icon: dedicated ? Icons.alt_route_outlined : Icons.swap_vert_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (apn != null) ...[
            DiagMetricTile(label: "APN", value: apn, width: null),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DiagMetricTile(
                label: "QCI",
                value: bearer["qci"]?.toString() ?? "-",
              ),
              if (pdnType != null)
                DiagMetricTile(label: "PDN", value: pdnType.toUpperCase()),
              if (!dedicated) ...[
                DiagMetricTile(
                  label: "APN-AMBR DL",
                  value: DiagHub.fmtRate(bearer["apn_ambr_dl_kbps"]),
                ),
                DiagMetricTile(
                  label: "APN-AMBR UL",
                  value: DiagHub.fmtRate(bearer["apn_ambr_ul_kbps"]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
