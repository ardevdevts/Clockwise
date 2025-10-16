import 'dart:ui';
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

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: themeDark.colorScheme.surface.withOpacity(0.8),
            child: Stack(
              children: [
                Row(
                  children: List.generate(
                    numberOfDestinations,
                    (index) => _buildNavItem(
                      index: index,
                      isSelected: currentIndex == index,
                      itemWidth: itemWidth,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  left: (currentIndex * itemWidth) + (itemWidth / 2) - 18,
                  bottom: 8,
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required bool isSelected,
    required double itemWidth,
  }) {
    final icons = [
      Icons.task_outlined,
      Icons.monitor_heart_outlined,
    ];
    final selectedIcons = [
      Icons.task,
      Icons.monitor_heart,
    ];

    return GestureDetector(
      onTap: () => onDestinationSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        height: 60,
        child: Center(
          child: Icon(
            isSelected ? selectedIcons[index] : icons[index],
            size: 24,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}