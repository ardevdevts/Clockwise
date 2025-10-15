import 'package:financialtracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final Widget navigationShell;
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final int numberOfDestinations;

  const CustomNavbar({
    super.key,
    required this.numberOfDestinations,
    required this.navigationShell,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width / numberOfDestinations;
    const double indicatorWidth = 20;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: themeDark.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: Colors.white);
                  }
                  return const IconThemeData(color: Colors.grey);
                }),
              ),
              child: NavigationBar(
                height: 80,
                selectedIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.task_outlined),
                    selectedIcon: Icon(Icons.task),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.monitor_heart_outlined),
                    selectedIcon: Icon(Icons.monitor_heart),
                    label: 'Habits',
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              bottom: 15,
              left: (currentIndex * itemWidth) + (itemWidth / numberOfDestinations) - (indicatorWidth / numberOfDestinations),
              width: indicatorWidth,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: themeDark.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}