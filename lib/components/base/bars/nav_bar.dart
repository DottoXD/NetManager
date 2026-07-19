import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class NavBar extends StatelessWidget {
  const NavBar(this.home, this.currentPage, {super.key});

  final Function(int) home;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    int page = currentPage;

    return NavigationBar(
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.person_outlined),
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
