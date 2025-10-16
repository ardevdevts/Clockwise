import 'package:financialtracker/core/services/service_providers.dart';
import 'package:financialtracker/features/habits/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'habit_reminders.dart';
import 'contribution_grid.dart';
import 'statistics_widgets.dart';
import 'chart_widgets.dart';

final selectedPeriodProvider = StateProvider<String>((ref) => '30');

// Habit Detail Page
class HabitDetailPage extends ConsumerWidget {
  final Habit habit;

  const HabitDetailPage({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitColor = Color(int.parse('FF${habit.color}', radix: 16));
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final habitWithDetails = ref.watch(habitWithDetailsProvider(habit.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: habitColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        PeriodSelector(
                          selected: selectedPeriod,
                          onChanged: (value) {
                            ref.read(selectedPeriodProvider.notifier).state =
                                value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    habitWithDetails.when(
                      data: (details) => StatisticsCards(
                        habitWithDetails: details,
                        habitColor: habitColor,
                        days: int.parse(selectedPeriod),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Progress Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Chart',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    habitWithDetails.when(
                      data: (details) => ProgressChart(
                        habitWithDetails: details,
                        habitColor: habitColor,
                        days: int.parse(selectedPeriod),
                      ),
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Weekly Trend Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Trend',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    habitWithDetails.when(
                      data: (details) => WeeklyTrendChart(
                        habitWithDetails: details,
                        habitColor: habitColor,
                      ),
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Contribution Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    habitWithDetails.when(
                      data: (details) => ContributionGrid(
                        habitWithDetails: details,
                        habitColor: habitColor,
                      ),
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Container(height: 0.5, color: AppColors.border),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Reminders
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await _showAddHabitReminderDialog(context, ref, habit);
                      },
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: HabitRemindersList(habitId: habit.id),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Container(height: 0.5, color: AppColors.border),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // History
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'History',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            habitWithDetails.when(
              data: (details) {
                final logs = details.logs;
                if (logs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No logs yet',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final log = logs[index];
                    final completionPercent =
                        habit.goalType == 'unit' && habit.goalValue != null
                        ? (log.amount / habit.goalValue!) * 100
                        : 100.0;

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getIntensityColor(
                                completionPercent,
                                habitColor,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEE, MMM d').format(log.date),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (habit.goalType == 'unit')
                            Row(
                              children: [
                                Text(
                                  '${log.amount.toStringAsFixed(0)} ${habit.goalUnit}',
                                  style: TextStyle(
                                    color: habitColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${completionPercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          else
                            Icon(
                              Icons.check_circle,
                              color: habitColor,
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }, childCount: logs.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showAddHabitReminderDialog(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
) async {
  final reminderService = ref.read(reminderServiceProvider);

  // Load existing reminders
  final existingReminders = await reminderService.getHabitReminders(habit.id);
  final List<ReminderTimeData> reminderTimes = existingReminders.map((r) {
    return ReminderTimeData(id: r.id, time: TimeOfDay.fromDateTime(r.remindAt));
  }).toList();

  TimeOfDay newTime = TimeOfDay.now();

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: AppColors.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habit Reminders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add or edit reminders for this habit',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // List of reminder times
              if (reminderTimes.isNotEmpty) ...[
                ...reminderTimes.map(
                  (reminderData) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reminderData.time.format(context),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        // Edit button
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.accentBlue,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: reminderData.time,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.accentBlue,
                                      surface: AppColors.elevatedSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                reminderData.time = time;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              reminderTimes.remove(reminderData);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add time button
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: newTime,
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.accentBlue,
                            surface: AppColors.elevatedSurface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() {
                      reminderTimes.add(ReminderTimeData(time: time));
                      newTime = time;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accentBlue, width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.accentBlue),
                      SizedBox(width: 8),
                      Text(
                        'Add Reminder Time',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();

                      // Delete removed reminders
                      for (final existingReminder in existingReminders) {
                        final stillExists = reminderTimes.any(
                          (r) => r.id == existingReminder.id,
                        );
                        if (!stillExists) {
                          await reminderService.removeReminder(
                            existingReminder.id,
                          );
                        }
                      }

                      // Update or create reminders
                      for (final reminderData in reminderTimes) {
                        var reminderTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          reminderData.time.hour,
                          reminderData.time.minute,
                        );

                        // If time has passed today, schedule for tomorrow
                        if (reminderTime.isBefore(now)) {
                          reminderTime = reminderTime.add(
                            const Duration(days: 1),
                          );
                        }

                        if (reminderData.id != null) {
                          // Update existing reminder
                          final existingReminder = existingReminders.firstWhere(
                            (r) => r.id == reminderData.id,
                          );
                          final database = ref.read(databaseProvider);
                          await database.updateReminder(
                            existingReminder.copyWith(remindAt: reminderTime),
                          );
                          final notificationService = ref.read(
                            notificationServiceProvider,
                          );
                          final notificationId =
                              (habit.id * 100000 + reminderData.id!).hashCode
                                  .abs();
                          await notificationService.scheduleHabitReminder(
                            habit,
                            reminderTime,
                            notificationId,
                          );
                        } else {
                          await reminderService.addHabitReminder(
                            habit.id,
                            reminderTime,
                            recurring: true,
                          );
                        }
                      }

                      if (context.mounted) Navigator.pop(context, true);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.accentBlue.withOpacity(0.15),
                      foregroundColor: AppColors.accentBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return result ?? false;
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
