import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
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
          builder: (context, _) => _Banner(
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

class _Banner extends StatelessWidget {
  final DiagConnState state;
  final String? error;

  const _Banner({required this.state, required this.error});

  @override
  Widget build(BuildContext context) {
    if (state == DiagConnState.connected) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    final String label;
    final IconData icon;
    final Color bg;
    final Color fg;

    switch (state) {
      case DiagConnState.connecting:
        label = appLocalizations.advancedModeDiagConnecting;
        icon = Icons.sync_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.disconnected:
        label = appLocalizations.advancedModeDiagDisconnected;
        icon = Icons.link_off_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.error:
        label = error ?? appLocalizations.advancedModeDiagError;
        icon = Icons.error_outlined;
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        break;
      case DiagConnState.connected:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
                _MetricTile(
                  label: "RSRP",
                  value: DiagHub.fmtNum(meas["rsrp_dbm"]),
                  unit: "dBm",
                ),
                _MetricTile(
                  label: "RSRQ",
                  value: DiagHub.fmtNum(meas["rsrq_db"]),
                  unit: "dB",
                ),
                _MetricTile(
                  label: "RSSI",
                  value: DiagHub.fmtNum(meas["rssi_dbm"]),
                  unit: "dBm",
                ),
                _MetricTile(
                  label: "EARFCN",
                  value: _fmtInt(meas["earfcn"]),
                  unit: "",
                ),
                _MetricTile(
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
                _MetricTile(
                  label: "Total DL BW",
                  value: info["dl_bandwidth_mhz"] != null
                      ? DiagHub.fmtNum(info["dl_bandwidth_mhz"])
                      : "—",
                  unit: info["dl_bandwidth_mhz"] != null ? "MHz" : "",
                ),
                _MetricTile(
                  label: "EARFCN",
                  value: _fmtInt(info["earfcn"]),
                  unit: "",
                ),
                _MetricTile(
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
