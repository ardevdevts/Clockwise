import 'package:financialtracker/features/habits/habit_with_details.dart';
import 'package:flutter/material.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';

// Contribution Grid Widget (GitHub-style)
class ContributionGrid extends StatelessWidget {
  final HabitWithDetails habitWithDetails;
  final Color habitColor;

  const ContributionGrid({
    super.key,
    required this.habitWithDetails,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    final logs = habitWithDetails.logs;
    final logMap = <String, HabitLog>{};
    for (final log in logs) {
      final key = _dateKey(log.date);
      logMap[key] = log;
    }

    return _buildGrid(logMap);
  }

  Widget _buildGrid(Map<String, HabitLog> logMap) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 90));

    // Calculate weeks
    final totalDays = 91; // ~13 weeks
    final weeks = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels
          SizedBox(
            width: weeks * 16.0,
            height: 20,
            child: Row(
              children: _buildMonthLabels(startDate, weeks),
            ),
          ),
          const SizedBox(height: 4),
          // Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final dayOffset = (weekIndex * 7) + dayIndex;
                    final date = startDate.add(Duration(days: dayOffset));

                    if (date.isAfter(endDate)) {
                      return const SizedBox(width: 12, height: 12);
                    }

                    final key = _dateKey(date);
                    final log = logMap[key];
                    final completionPercent = _getCompletionPercent(log);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Tooltip(
                        message: _getTooltip(date, log),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getIntensityColor(completionPercent, habitColor),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 6),
              _buildLegendBox(0),
              const SizedBox(width: 3),
              _buildLegendBox(25),
              const SizedBox(width: 3),
              _buildLegendBox(50),
              const SizedBox(width: 3),
              _buildLegendBox(75),
              const SizedBox(width: 3),
              _buildLegendBox(100),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(double percent) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getIntensityColor(percent, habitColor),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(DateTime startDate, int weeks) {
    final labels = <Widget>[];
    String? lastMonth;

    for (int i = 0; i < weeks; i++) {
      final date = startDate.add(Duration(days: i * 7));
      final monthName = DateFormat('MMM').format(date);

      if (monthName != lastMonth) {
        labels.add(
          Expanded(
            child: Text(
              monthName,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        lastMonth = monthName;
      }
    }

    return labels;
  }

  double _getCompletionPercent(HabitLog? log) {
    if (log == null) return 0;
    final habit = habitWithDetails.habit;

    if (habit.goalType == 'boolean') {
      return 100;
    } else if (habit.goalValue != null && habit.goalValue! > 0) {
      final percent = (log.amount / habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }

    return 0;
  }

  String _getTooltip(DateTime date, HabitLog? log) {
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    final habit = habitWithDetails.habit;

    if (log == null) {
      return '$dateStr\nNo activity';
    }

    if (habit.goalType == 'boolean') {
      return '$dateStr\nCompleted';
    } else {
      final percent = _getCompletionPercent(log);
      return '$dateStr\n${log.amount.toStringAsFixed(0)} ${habit.goalUnit} (${percent.toStringAsFixed(0)}%)';
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Helper function for intensity color
Color _getIntensityColor(double completionPercent, Color baseColor) {
  if (completionPercent == 0) {
    return AppColors.surface;
  } else if (completionPercent < 25) {
    return baseColor.withOpacity(0.3);
  } else if (completionPercent < 50) {
    return baseColor.withOpacity(0.5);
  } else if (completionPercent < 75) {
    return baseColor.withOpacity(0.7);
  } else if (completionPercent < 100) {
    return baseColor.withOpacity(0.85);
  } else {
    return baseColor;
  }
}
