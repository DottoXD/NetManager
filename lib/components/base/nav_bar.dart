import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavBar extends StatelessWidget {
  const NavBar(this.home, this.currentPage, {super.key});

  final Function home;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    int page = currentPage;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromARGB(0, 255, 255, 255),
      ),
      child: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: "Data",
            //tooltip: "Cell data info", - i wanna make tooltips for the other pages too first
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            label: "Map",
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
      ),
    );
  }
}
