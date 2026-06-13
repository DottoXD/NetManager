import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar(this.home, this.currentPage, {super.key});

  final Function home;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    int page = currentPage;

    return NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.person_outlined), label: "Data"),
        NavigationDestination(
          icon: Icon(Icons.location_searching_outlined),
          label: "Map",
        ),
        NavigationDestination(
          icon: Icon(Icons.speed_outlined),
          label: "Speed test",
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: "Settings",
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
