




import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_navbar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final int numberOfDestinations;
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell, required this.numberOfDestinations});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomNavbar(  
        navigationShell: navigationShell,
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        numberOfDestinations: numberOfDestinations,
      ),
    );
  }
}