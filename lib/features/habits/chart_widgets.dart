import 'package:financialtracker/database/crud.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';

// Progress Chart Widget
class ProgressChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const ProgressChart({
    super.key,
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<DateTime, double>>(
      future: database.getDailyHabitLogs(habit.id, days: days),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final dailyLogs = snapshot.data!;
        if (dailyLogs.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'No data to display',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: days - 1));
        final List<FlSpot> spots = [];

        for (var i = 0; i < days; i++) {
          final date = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
          final value = dailyLogs[date] ?? 0.0;
          spots.add(FlSpot(i.toDouble(), value));
        }

        final maxY = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final adjustedMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: adjustedMaxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: days > 30 ? (days / 6).floorToDouble() : 7,
                    getTitlesWidget: (value, meta) {
                      final date = startDate.add(Duration(days: value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('M/d').format(date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (days - 1).toDouble(),
              minY: 0,
              maxY: adjustedMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: habitColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: days <= 30,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: habitColor,
                        strokeWidth: 1,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: habitColor.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => AppColors.elevatedSurface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = startDate.add(Duration(days: spot.x.toInt()));
                      return LineTooltipItem(
                        '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(1)} ${habit.goalUnit ?? ''}',
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Weekly Trend Chart Widget
class WeeklyTrendChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;

  const WeeklyTrendChart({
    super.key,
    required this.habit,
    required this.database,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.getWeeklyHabitStats(habit.id, weeks: 12),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
            ),
          );
        }

        final weeklyStats = snapshot.data!;
        if (weeklyStats.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'No data to display',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }

        final maxCount = weeklyStats.isEmpty ? 10.0 : weeklyStats.map((s) => s['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
        final adjustedMaxY = maxCount == 0 ? 10.0 : maxCount * 1.2;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: adjustedMaxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: adjustedMaxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= weeklyStats.length) return const Text('');
                      final weekStart = weeklyStats[value.toInt()]['weekStart'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('M/d').format(weekStart),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: weeklyStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (stat['count'] as int).toDouble(),
                      color: habitColor,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.elevatedSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = weeklyStats[groupIndex];
                    final weekStart = stat['weekStart'] as DateTime;
                    final count = stat['count'] as int;
                    return BarTooltipItem(
                      'Week of ${DateFormat('MMM d').format(weekStart)}\n$count logs',
                      const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
