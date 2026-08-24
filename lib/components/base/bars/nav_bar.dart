import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class NavBar extends StatelessWidget {
  const NavBar(this.home, this.currentPage, {super.key});

  final Function(int) home;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    if (appLocalizations == null) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);

    int page = currentPage;

    return NavigationBar(
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        final baseStyle = theme.textTheme.labelMedium ?? const TextStyle();

        return baseStyle.copyWith(
          overflow: TextOverflow.ellipsis,
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        );
      }),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.cell_tower_outlined),
          label: appLocalizations.navData,
        ),
        NavigationDestination(
          icon: const Icon(Icons.location_searching_outlined),
          label: appLocalizations.navMap,
        ),
        NavigationDestination(
          icon: const Icon(Icons.speed_outlined),
          label: appLocalizations.navSpeedtest,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          label: appLocalizations.navSettings,
        ),
      ],
      selectedIndex: page,
      onDestinationSelected: (index) {
        page = index;
        home(page);
      },
    );
  }
}
