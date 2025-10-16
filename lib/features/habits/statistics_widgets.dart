import 'package:financialtracker/database/crud.dart';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

// Period Selector Widget
class PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['7', '30', '90'].map((period) {
          final isSelected = period == selected;
          return GestureDetector(
            onTap: () => onChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$period days',
                style: TextStyle(
                  color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Statistics Cards Widget
class StatisticsCards extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const StatisticsCards({
    super.key,
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: database.getHabitStats(habit.id, days: days),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final stats = snapshot.data!;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Completion',
                    value: '${stats['completionRate'].toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Logs',
                    value: '${stats['totalLogs']}',
                    icon: Icons.calendar_month,
                    color: habitColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Current Streak',
                    value: '${stats['currentStreak']} days',
                    icon: Icons.local_fire_department,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Longest Streak',
                    value: '${stats['longestStreak']} days',
                    icon: Icons.emoji_events,
                    color: habitColor,
                  ),
                ),
              ],
            ),
            if (habit.goalType == 'unit') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Average',
                      value: '${stats['averageAmount'].toStringAsFixed(1)} ${habit.goalUnit}',
                      icon: Icons.analytics,
                      color: habitColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total',
                      value: '${stats['totalAmount'].toStringAsFixed(0)} ${habit.goalUnit}',
                      icon: Icons.functions,
                      color: habitColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// Individual Stat Card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
