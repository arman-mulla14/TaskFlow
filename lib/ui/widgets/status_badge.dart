import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/task_model.dart';
import '../../data/models/project_model.dart';

class StatusBadge extends StatelessWidget {
  final dynamic status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = '';

    final isCompleted = (status == TaskStatus.completed || status == ProjectStatus.completed);
    final isInProgress = (status == TaskStatus.inProgress || status == ProjectStatus.inProgress);

    if (isCompleted) {
      bg = AppColors.success.withOpacity(0.15);
      fg = AppColors.success;
      label = 'Completed';
    } else if (isInProgress) {
      bg = AppColors.primaryAccent.withOpacity(0.15);
      fg = AppColors.primaryAccent;
      label = 'In Progress';
    } else {
      bg = Colors.grey.withOpacity(0.15);
      fg = Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextMuted
          : AppColors.lightTextMuted;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
