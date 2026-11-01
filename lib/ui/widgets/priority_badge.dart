import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/task_model.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (priority) {
      case TaskPriority.high:
        bg = AppColors.priorityHigh.withOpacity(0.15);
        fg = AppColors.priorityHigh;
        break;
      case TaskPriority.medium:
        bg = AppColors.priorityMedium.withOpacity(0.15);
        fg = AppColors.priorityMedium;
        break;
      case TaskPriority.low:
        bg = AppColors.priorityLow.withOpacity(0.15);
        fg = AppColors.priorityLow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
