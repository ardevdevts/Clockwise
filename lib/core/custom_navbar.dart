import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
      height: 70,
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
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  left: (currentIndex * itemWidth) + (itemWidth / 2) - 20,
                  bottom: 4,
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: const Color(0xFF2196F3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
    // Using Material Icons as fallback since HugeIcons requires specific implementation
    final icons = [
      HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedHeartCheck,
      HugeIcons.strokeRoundedUser,
    ];
    final selectedIcons = [
      HugeIcons.strokeRoundedHome01,
      HugeIcons.strokeRoundedHeartCheck,
      HugeIcons.strokeRoundedUser,
    ];
    final labels = [
      'Tasks',
      'Habits',
      'Notes',
    ];

    return GestureDetector(
      onTap: () {
        onDestinationSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: itemWidth,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()
                ..scale(isSelected ? 1.1 : 1.0),
              child: HugeIcon(
                icon: isSelected ? selectedIcons[index] : icons[index],
                size: 26,
                color: isSelected 
                    ? const Color(0xFF2196F3) 
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey.shade600.withOpacity(0.7),
                letterSpacing: 0.3,
              ),
              child: Text(labels[index]),
            ),
          ],
        ),
      ),
    );
  }
}