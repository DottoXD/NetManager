import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_widgets.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class LteServingCellPage extends StatelessWidget {
  final ValueListenable<int> simSlotNotifier;

  const LteServingCellPage({super.key, required this.simSlotNotifier});

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
            diagHub.status,
            simSlotNotifier,
          ]),
          builder: (context, _) =>
              _Body(hub: diagHub, slot: simSlotNotifier.value),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final DiagHub hub;
  final int slot;

  const _Body({required this.hub, required this.slot});

  static String _fmtInt(dynamic n) => n == null ? "-" : n.toString();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final meas = hub.servingMeasFor(slot);
    final info = hub.cellInfoFor(slot);
    final sim = appLocalizations.advancedModeSimLabel(slot + 1);

    if (meas == null &&
        info == null &&
        hub.connState.value == DiagConnState.connected) {
      return InfoCard(
        title: appLocalizations.advancedModeLteServingTitle,
        icon: Icons.network_cell_outlined,
        child: _Waiting(text: _waitingText(appLocalizations, sim)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (meas != null)
          InfoCard(
            title: appLocalizations.advancedModeLteServingTitle,
            icon: Icons.network_cell_outlined,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DiagMetricTile(
                  label: "RSRP",
                  value: DiagHub.fmtNum(meas["rsrp_dbm"]),
                  unit: "dBm",
                ),
                DiagMetricTile(
                  label: "RSRQ",
                  value: DiagHub.fmtNum(meas["rsrq_db"]),
                  unit: "dB",
                ),
                DiagMetricTile(
                  label: "RSSI",
                  value: DiagHub.fmtNum(meas["rssi_dbm"]),
                  unit: "dBm",
                ),
                DiagMetricTile(
                  label: "EARFCN",
                  value: _fmtInt(meas["earfcn"]),
                  unit: "",
                ),
                DiagMetricTile(
                  label: "PCI",
                  value: _fmtInt(meas["pci"]),
                  unit: "",
                ),
              ],
            ),
          ),
        if (meas != null && info != null) const SizedBox(height: 12),
        if (info != null)
          InfoCard(
            title: appLocalizations.advancedModeLteCellInfoTitle,
            icon: Icons.speed_outlined,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DiagMetricTile(
                  label: "Total DL BW",
                  value: info["dl_bandwidth_mhz"] != null
                      ? DiagHub.fmtNum(info["dl_bandwidth_mhz"])
                      : "—",
                  unit: info["dl_bandwidth_mhz"] != null ? "MHz" : "",
                ),
                DiagMetricTile(
                  label: "EARFCN",
                  value: _fmtInt(info["earfcn"]),
                  unit: "",
                ),
                DiagMetricTile(
                  label: "PCI",
                  value: _fmtInt(info["pci"]),
                  unit: "",
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _waitingText(AppLocalizations appLocalizations, String sim) {
    if (hub.modemTagsSlots && !hub.slotsSeen.contains(slot)) {
      final others = hub.slotsSeen
          .map((s) => appLocalizations.advancedModeSimLabel(s + 1))
          .join(", ");
      return appLocalizations.advancedModeLteNoData(sim, others);
    }
    return appLocalizations.advancedModeLteWaiting;
  }
}

class _Waiting extends StatelessWidget {
  final String text;

  const _Waiting({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
