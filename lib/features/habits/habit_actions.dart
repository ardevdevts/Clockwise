import 'package:flutter/material.dart';
import '../../database/crud.dart';
import '../../core/theme/colors.dart';
import 'habit_detail_page.dart';

void showHabitDetail(BuildContext context, Habit habit) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HabitDetailPage(habit: habit),
    ),
  );
}

void deleteHabit(BuildContext context, AppDatabase database, Habit habit) {
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
            const Text(
              'Delete Habit',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete "${habit.name}"?\nAll logs will be removed.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                _MinimalButton(
                  label: 'Delete',
                  onPressed: () async {
                    await database.deleteHabit(habit.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Minimal Button for delete dialog
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
