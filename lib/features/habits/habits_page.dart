import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'habit_dialog.dart';
import 'habit_actions.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final selectedDate = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Habit>>(
          stream: database.watchActiveHabits(),
          builder: (context, snapshot) {
            final isLoading = !snapshot.hasData && 
                             snapshot.connectionState == ConnectionState.waiting;
            
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              );
            }

            final habits = snapshot.data ?? [];

            if (habits.isEmpty) {
              return Column(
                children: [
                  // Header
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
                          icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
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
                          Icon(
                            Icons.track_changes_outlined,
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

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.background,
                  floating: true,
                  snap: true,
                  toolbarHeight: 72,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
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
                          icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }
                        final habitIndex = index ~/ 2;
                        return _HabitCard(
                          habit: habits[habitIndex],
                          selectedDate: selectedDate,
                          database: database,
                          onTap: () => showHabitDetail(context, habits[habitIndex]),
                          onEdit: () => showDialog(
                            context: context,
                            barrierColor: Colors.black87,
                            builder: (context) => HabitDialog(database: database, habit: habits[habitIndex]),
                          ),
                          onDelete: () => deleteHabit(context, database, habits[habitIndex]),
                        );
                      },
                      childCount: habits.length * 2 - 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Habit Card Widget
class _HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final AppDatabase database;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.selectedDate,
    required this.database,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> {
  // Optimistic state - stores the current state for this specific habit
  HabitLog? _localLog;
  bool _isInitialized = false;
  HabitLog? _lastLog;
  bool _isPendingOptimisticUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadLastLog();
  }

  @override
  void didUpdateWidget(_HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset initialization if the selected date changes
    if (oldWidget.selectedDate != widget.selectedDate) {
      _isInitialized = false;
      _localLog = null;
      _isPendingOptimisticUpdate = false;
    }
    // Reload last log if habit changes
    if (oldWidget.habit.id != widget.habit.id) {
      _loadLastLog();
    }
  }

  Future<void> _loadLastLog() async {
    try {
      final lastLog = await widget.database.getLastHabitLog(widget.habit.id);
      if (mounted) {
        setState(() {
          _lastLog = lastLog;
        });
      }
    } catch (e) {
      // Silently fail - _lastLog will remain null
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(int.parse('FF${widget.habit.color}', radix: 16));

    return StreamBuilder<HabitLog?>(
      stream: widget.database.watchHabitLogForDate(widget.habit.id, widget.selectedDate),
      builder: (context, currentLogSnapshot) {
        // Initialize local state from stream only once
        if (!_isInitialized) {
          if (currentLogSnapshot.hasData) {
            _localLog = currentLogSnapshot.data;
            _isInitialized = true;
          } else if (currentLogSnapshot.connectionState != ConnectionState.waiting) {
            _isInitialized = true;
          }
        } else if (!_isPendingOptimisticUpdate && currentLogSnapshot.connectionState == ConnectionState.active) {
          // Only update from stream if we don't have a pending optimistic update
          final streamLog = currentLogSnapshot.data;
          _localLog = streamLog;
        }
        
        // Clear pending flag after stream has stabilized
        if (_isPendingOptimisticUpdate && currentLogSnapshot.connectionState == ConnectionState.active) {
          // Wait one more frame to ensure DB operation completed
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isPendingOptimisticUpdate = false;
              });
            }
          });
        }
        
        // Always use local state for display
        final log = _localLog;
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
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title, Description, Completion & Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color indicator
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: habitColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Habit info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.habit.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (widget.habit.description != null && widget.habit.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.habit.description!,
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

                        // Completion indicator
                        if (widget.habit.goalType == 'boolean')
                          GestureDetector(
                            onTap: () => _toggleHabit(isCompleted, log),
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
                                boxShadow: isCompleted ? [
                                  BoxShadow(
                                    color: habitColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _showUnitInput(context, log, currentProgress),
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
                                    ? '${currentProgress.toStringAsFixed(0)}/${widget.habit.goalValue?.toStringAsFixed(0)}' 
                                    : '0/${widget.habit.goalValue?.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: habitColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // More menu
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: habitColor.withOpacity(0.7), size: 20),
                          color: AppColors.elevatedSurface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          offset: const Offset(-12, 0),
                          onSelected: (value) {
                            if (value == 'edit') {
                              widget.onEdit();
                            } else if (value == 'delete') {
                              widget.onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                                  const SizedBox(width: 12),
                                  Text('Edit', style: TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  const SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Row 2: Contribution Grid (Full Width)
                    const SizedBox(height: 16),
                    _CompactContributionGrid(
                      habit: widget.habit,
                      database: widget.database,
                      habitColor: habitColor,
                      currentDateLog: _localLog,
                      selectedDate: widget.selectedDate,
                    ),
                    
                    // Row 3: Stats row
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Goal info on the left
                        if (widget.habit.goalType == 'unit' && widget.habit.goalUnit != null)
                          Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Goal: ${widget.habit.goalValue?.toStringAsFixed(0)} ${widget.habit.goalUnit}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        // Last completion time on the right
                        if (_lastLog != null)
                          Row(
                            children: [
                              Icon(Icons.history, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Last: ${DateFormat('MMM d').format(_lastLog!.date)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleHabit(bool isCompleted, HabitLog? log) async {
    setState(() {
      _isPendingOptimisticUpdate = true;
      if (isCompleted && log != null) {
        _localLog = null;
      } else {
        _localLog = HabitLog(
          id: log?.id ?? -1, 
          habitId: widget.habit.id,
          date: widget.selectedDate,
          amount: 1,
        );
      }
    });

    try {
      if (isCompleted && log != null) {
        await widget.database.deleteHabitLogById(log.id);
      } else {
        await widget.database.upsertHabitLog(widget.habit.id, widget.selectedDate, 1);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localLog = log; 
          _isPendingOptimisticUpdate = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update habit: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showUnitInput(BuildContext context, HabitLog? log, double currentProgress) {
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
                widget.habit.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${widget.habit.goalValue?.toStringAsFixed(0)} ${widget.habit.goalUnit}',
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
                  suffixText: widget.habit.goalUnit,
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
                      onPressed: () async {
                        // Close dialog and update local state immediately
                        Navigator.pop(context);
                        
                        final previousLog = _localLog;
                        setState(() {
                          _isPendingOptimisticUpdate = true;
                          _localLog = null;
                        });
                        
                        try {
                          await widget.database.deleteHabitLogById(log.id);
                        } catch (e) {
                          // Revert on error
                          if (mounted) {
                            setState(() {
                              _localLog = previousLog;
                              _isPendingOptimisticUpdate = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to clear habit: $e'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
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
                  _MinimalButton(
                    label: 'Save',
                    onPressed: () async {
                      final amount = double.tryParse(controller.text);
                      if (amount == null || amount <= 0) return;

                      // Close dialog immediately
                      Navigator.pop(context);
                      
                      // Store previous state for rollback
                      final previousLog = _localLog;
                      
                      // Update local state immediately
                      setState(() {
                        _isPendingOptimisticUpdate = true;
                        _localLog = HabitLog(
                          id: log?.id ?? -1,
                          habitId: widget.habit.id,
                          date: widget.selectedDate,
                          amount: amount,
                        );
                      });

                      // Perform database operation in background
                      try {
                        await widget.database.upsertHabitLog(widget.habit.id, widget.selectedDate, amount);
                      } catch (e) {
                        // Revert on error
                        if (mounted) {
                          setState(() {
                            _localLog = previousLog;
                            _isPendingOptimisticUpdate = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save habit: $e'),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact Contribution Grid for Habit Card
class _CompactContributionGrid extends StatefulWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final HabitLog? currentDateLog;
  final DateTime selectedDate;

  const _CompactContributionGrid({
    required this.habit,
    required this.database,
    required this.habitColor,
    required this.currentDateLog,
    required this.selectedDate,
  });

  @override
  State<_CompactContributionGrid> createState() => _CompactContributionGridState();
}

class _CompactContributionGridState extends State<_CompactContributionGrid> {
  Map<String, HabitLog> _logMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void didUpdateWidget(_CompactContributionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if habit changes
    if (oldWidget.habit.id != widget.habit.id) {
      _loadLogs();
    } else if (oldWidget.currentDateLog != widget.currentDateLog) {
      // Optimistically update the current date log in the map
      _updateCurrentDateLog();
    }
  }

  void _updateCurrentDateLog() {
    setState(() {
      final key = _dateKey(widget.selectedDate);
      if (widget.currentDateLog != null) {
        _logMap[key] = widget.currentDateLog!;
      } else {
        _logMap.remove(key);
      }
    });
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await widget.database.getHabitLogs(widget.habit.id);
      if (!mounted) return;
      
      final logMap = <String, HabitLog>{};
      for (final log in logs) {
        final key = _dateKey(log.date);
        logMap[key] = log;
      }

      // Apply current date log optimistically
      final currentKey = _dateKey(widget.selectedDate);
      if (widget.currentDateLog != null) {
        logMap[currentKey] = widget.currentDateLog!;
      } else {
        logMap.remove(currentKey);
      }

      setState(() {
        _logMap = logMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logMap = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 60);
    }

    return _buildFullWidthGrid(_logMap);
  }

  Widget _buildFullWidthGrid(Map<String, HabitLog> logMap) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    
    // Calculate 6 months back (approximately 26 weeks)
    final startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate square size to fit width
        final availableWidth = constraints.maxWidth;
        final spacing = 3.0;
        final totalSpacing = (weeks - 1) * spacing;
        final squareSize = ((availableWidth - totalSpacing) / weeks).floorToDouble();
        final actualSquareSize = ((squareSize - (6 * spacing)) / 7).floorToDouble();
        
        // Make squares bigger (minimum 10px)
        final finalSquareSize = actualSquareSize < 10 ? 10.0 : actualSquareSize;
        
        // Create scroll controller to start at the end (most recent)
        final scrollController = ScrollController(
          initialScrollOffset: double.maxFinite,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels
            SizedBox(
              height: 18,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildMonthLabels(startDate, weeks, finalSquareSize, spacing),
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Grid
            SizedBox(
              height: (finalSquareSize * 7) + (6 * spacing),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Start from the end (most recent)
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeks, (weekIndex) {
                    return Padding(
                      padding: EdgeInsets.only(right: weekIndex < weeks - 1 ? spacing : 0),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          final dayOffset = (weekIndex * 7) + dayIndex;
                          final date = startDate.add(Duration(days: dayOffset));
                          
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
                            padding: EdgeInsets.only(bottom: dayIndex < 6 ? spacing : 0),
                            child: Container(
                              width: finalSquareSize,
                              height: finalSquareSize,
                              decoration: BoxDecoration(
                                color: _getIntensityColor(completionPercent, widget.habitColor),
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
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMonthLabels(DateTime startDate, int weeks, double squareSize, double spacing) {
    final labels = <Widget>[];
    final monthWidths = <String, double>{};
    
    // Calculate which month each week belongs to
    for (int i = 0; i < weeks; i++) {
      final date = startDate.add(Duration(days: i * 7));
      final monthKey = '${date.year}-${date.month}';
      
      if (!monthWidths.containsKey(monthKey)) {
        monthWidths[monthKey] = 0;
      }
      monthWidths[monthKey] = monthWidths[monthKey]! + squareSize + spacing;
    }
    
    // Build month label widgets
    monthWidths.forEach((key, width) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final monthName = DateFormat('MMM').format(date);
      
      labels.add(
        SizedBox(
          width: width - spacing,
          child: Text(
            monthName,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
    
    return labels;
  }

  double _getCompletionPercent(HabitLog? log) {
    if (log == null) return 0;
    
    if (widget.habit.goalType == 'boolean') {
      return 100;
    } else if (widget.habit.goalValue != null && widget.habit.goalValue! > 0) {
      final percent = (log.amount / widget.habit.goalValue!) * 100;
      return percent.clamp(0, 100);
    }
    
    return 0;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Helper function for intensity color used by the compact contribution grid
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

// Minimal UI Components
class _MinimalTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _MinimalTextField({
    this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _MinimalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _MinimalButton({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDestructive 
            ? AppColors.error.withOpacity(0.15) 
            : AppColors.accentBlue.withOpacity(0.15),
        foregroundColor: isDestructive ? AppColors.error : AppColors.accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

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


// Period Selector Widget
class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
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
class _StatisticsCards extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const _StatisticsCards({
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
                  child: _StatCard(
                    title: 'Completion',
                    value: '${stats['completionRate'].toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
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
                  child: _StatCard(
                    title: 'Current Streak',
                    value: '${stats['currentStreak']} days',
                    icon: Icons.local_fire_department,
                    color: habitColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
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
                    child: _StatCard(
                      title: 'Average',
                      value: '${stats['averageAmount'].toStringAsFixed(1)} ${habit.goalUnit}',
                      icon: Icons.analytics,
                      color: habitColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
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
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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

// Progress Chart Widget
class _ProgressChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;
  final int days;

  const _ProgressChart({
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
class _WeeklyTrendChart extends StatelessWidget {
  final Habit habit;
  final AppDatabase database;
  final Color habitColor;

  const _WeeklyTrendChart({
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


