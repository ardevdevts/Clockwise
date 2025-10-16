import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        final index = options.indexOf(option);
        final isFirst = index == 0;
        final isLast = index == options.length - 1;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentBlue.withOpacity(0.15)
                    : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.accentBlue : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(6) : Radius.zero,
                  right: isLast ? const Radius.circular(6) : Radius.zero,
                ),
              ),
              child: Text(
                option.substring(0, 1).toUpperCase() + option.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Day Selector Widget
class _DaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onDaysChanged;

  const _DaySelector({
    required this.selectedDays,
    required this.onDaysChanged,
  });

  static const List<String> dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(index);
            } else {
              newDays.add(index);
            }
            onDaysChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentBlue.withOpacity(0.2)
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accentBlue : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                dayNames[index],
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
