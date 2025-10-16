import 'package:financialtracker/core/theme/colors.dart';
import 'package:financialtracker/database/crud.dart';
import 'package:financialtracker/features/habits/habit_actions.dart';
import 'package:financialtracker/features/habits/habit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/database_provider.dart';
import 'package:hugeicons/hugeicons.dart';

// Data class to hold a habit and all its required details for the UI.
// This allows fetching all data in one go, preventing N+1 queries.
class HabitWithDetails {
  final Habit habit;
  final HabitLog? todayLog;
  final HabitLog? lastLog;
  final Map<String, HabitLog> recentLogs; // For the contribution grid

  HabitWithDetails({
    required this.habit,
    this.todayLog,
    this.lastLog,
    required this.recentLogs,
  });
}

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final selectedDate = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<HabitWithDetails>>(
          stream: database.watchActiveHabitsWithDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              );
            }

            final habitsWithDetails = snapshot.data ?? [];

            if (habitsWithDetails.isEmpty) {
              return _buildEmptyState(context, database);
            }

            return CustomScrollView(
              slivers: [
                _buildAppBar(context, database),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  sliver: SliverList.separated(
                    itemCount: habitsWithDetails.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final habitDetails = habitsWithDetails[index];
                      return _HabitCard(
                        habitDetails: habitDetails,
                        selectedDate: selectedDate,
                        database: database,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppDatabase database) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Habits',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierColor: Colors.black87,
                  builder: (context) => HabitDialog(database: database),
                ),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.textPrimary, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedTarget01,
                  size: 64,
                  color: AppColors.gray500,
                ),
                const SizedBox(height: 20),
                Text(
                  'No habits yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to start building better routines!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppDatabase database) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      snap: true,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      title: const Text(
        'Habits',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => showDialog(
            context: context,
            barrierColor: Colors.black87,
            builder: (context) => HabitDialog(database: database),
          ),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.textPrimary, size: 28),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

// Habit Card Widget - Now a much simpler StatelessWidget
class _HabitCard extends StatelessWidget {
  final HabitWithDetails habitDetails;
  final DateTime selectedDate;
  final AppDatabase database;

  const _HabitCard({
    required this.habitDetails,
    required this.selectedDate,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    final habit = habitDetails.habit;
    final log = habitDetails.todayLog;
    final lastLog = habitDetails.lastLog;
    final habitColor = Color(int.parse('FF${habit.color}', radix: 16));
    final isCompleted = log != null;
    final currentProgress = log?.amount ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: habitColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habitColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: habitColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showHabitDetail(context, habit),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(context, habit, log, habitColor, isCompleted, currentProgress),
                const SizedBox(height: 16),
                _CompactContributionGrid(
                  habit: habit,
                  habitColor: habitColor,
                  logMap: habitDetails.recentLogs,
                ),
                const SizedBox(height: 12),
                _buildCardFooter(habit, lastLog),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, Habit habit, HabitLog? log, Color habitColor, bool isCompleted, double currentProgress) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: habitColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (habit.description != null && habit.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  habit.description!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (habit.goalType == 'boolean')
          _BooleanHabitControl(database: database, habit: habit, log: log, habitColor: habitColor, isCompleted: isCompleted)
        else
          _UnitHabitControl(database: database, habit: habit, log: log, habitColor: habitColor, isCompleted: isCompleted, currentProgress: currentProgress),
        _MoreMenu(database: database, habit: habit),
      ],
    );
  }

  Widget _buildCardFooter(Habit habit, HabitLog? lastLog) {
    return Row(
      children: [
        if (habit.goalType == 'unit' && habit.goalUnit != null)
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedFlag01, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Goal: ${habit.goalValue?.toStringAsFixed(0)} ${habit.goalUnit}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        const Spacer(),
        if (lastLog != null)
          Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Last: ${DateFormat('MMM d').format(lastLog.date)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.database,
    required this.habit,
  });

  final AppDatabase database;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreHorizontal, color: Color(int.parse('FF${habit.color}', radix: 16)).withOpacity(0.7), size: 20),
      color: AppColors.elevatedSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      offset: const Offset(-12, 0),
      onSelected: (value) {
        if (value == 'edit') {
          showDialog(
            context: context,
            barrierColor: Colors.black87,
            builder: (context) => HabitDialog(database: database, habit: habit),
          );
        } else if (value == 'delete') {
          deleteHabit(context, database, habit);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('Edit', style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BooleanHabitControl extends StatelessWidget {
  const _BooleanHabitControl({
    required this.database,
    required this.habit,
    required this.log,
    required this.habitColor,
    required this.isCompleted,
  });

  final AppDatabase database;
  final Habit habit;
  final HabitLog? log;
  final Color habitColor;
  final bool isCompleted;

  void _toggleHabit() {
    if (isCompleted && log != null) {
      database.deleteHabitLogById(log!.id);
    } else {
      database.upsertHabitLog(habit.id, DateTime.now(), 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleHabit,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCompleted ? habitColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: habitColor,
            width: 2.5,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: habitColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isCompleted
            ? const HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _UnitHabitControl extends StatelessWidget {
  const _UnitHabitControl({
    required this.database,
    required this.habit,
    required this.log,
    required this.habitColor,
    required this.isCompleted,
    required this.currentProgress,
  });

  final AppDatabase database;
  final Habit habit;
  final HabitLog? log;
  final Color habitColor;
  final bool isCompleted;
  final double currentProgress;

  void _showUnitInput(BuildContext context) {
    final controller = TextEditingController(
      text: currentProgress > 0 ? currentProgress.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${habit.goalValue?.toStringAsFixed(0)} ${habit.goalUnit}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: habit.goalUnit,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (log != null)
                    TextButton(
                      onPressed: () {
                        database.deleteHabitLogById(log!.id);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      final amount = double.tryParse(controller.text);
                      if (amount == null || amount <= 0) return;
                      database.upsertHabitLog(habit.id, DateTime.now(), amount);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUnitInput(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCompleted
              ? habitColor.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: habitColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Text(
          isCompleted
              ? '${currentProgress.toStringAsFixed(0)}/${habit.goalValue?.toStringAsFixed(0)}'
              : '0/${habit.goalValue?.toStringAsFixed(0)}',
          style: TextStyle(
            color: habitColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Compact Contribution Grid for Habit Card - Now a StatelessWidget
class _CompactContributionGrid extends StatelessWidget {
  final Habit habit;
  final Color habitColor;
  final Map<String, HabitLog> logMap;

  const _CompactContributionGrid({
    required this.habit,
    required this.habitColor,
    required this.logMap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildFullWidthGrid(logMap);
  }

  Widget _buildFullWidthGrid(Map<String, HabitLog> logMap) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 180)); // Approx 6 months
    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 3.0;
        final squareSize = (availableWidth / weeks) - spacing;
        final finalSquareSize = squareSize < 0 ? 0.0 : squareSize;

        return SizedBox(
          height: (finalSquareSize * 7) + (spacing * 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Start from the end (most recent)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (weekIndex) {
                return Padding(
                  padding: EdgeInsets.only(left: weekIndex > 0 ? spacing : 0),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(Duration(days: (weekIndex * 7) + dayIndex));

                      if (date.isAfter(endDate)) {
                        return SizedBox(
                          width: finalSquareSize,
                          height: finalSquareSize,
                        );
                      }

                      final key = _dateKey(date);
                      final log = logMap[key];
                      final completionPercent = _getCompletionPercent(log);

                      return Padding(
                        padding: EdgeInsets.only(top: dayIndex > 0 ? spacing : 0),
                        child: Container(
                          width: finalSquareSize,
                          height: finalSquareSize,
                          decoration: BoxDecoration(
                            color: _getIntensityColor(completionPercent, habitColor),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  double _getCompletionPercent(HabitLog? log) {
    if (log == null) return 0;

    if (habit.goalType == 'boolean') {
      return 100;
    } else if (habit.goalValue != null && habit.goalValue! > 0) {
      final percent = (log.amount / habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }

    return 0;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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
}