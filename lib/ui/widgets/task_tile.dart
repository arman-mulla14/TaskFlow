import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/task_model.dart';
import 'priority_badge.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final String? phaseName;
  final ValueChanged<bool?> onCheckboxChanged;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddNote;

  const TaskTile({
    super.key,
    required this.task,
    this.phaseName,
    required this.onCheckboxChanged,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final isOverdue = DateFormatter.isOverdue(task.dueDate) && !task.isCompleted;
    final isDueToday = DateFormatter.isToday(task.dueDate) && !task.isCompleted;

    return Card(
      color: cardBg,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: onCheckboxChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? textMuted : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textMuted,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityBadge(priority: task.priority),
                        if (phaseName != null && phaseName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              phaseName!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryAccentLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (task.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? AppColors.danger.withOpacity(0.15)
                                  : isDueToday
                                      ? AppColors.warning.withOpacity(0.15)
                                      : textMuted.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 11,
                                  color: isOverdue
                                      ? AppColors.danger
                                      : isDueToday
                                          ? AppColors.warning
                                          : textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormatter.getRelativeDueDate(task.dueDate),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue
                                        ? AppColors.danger
                                        : isDueToday
                                            ? AppColors.warning
                                            : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (task.notes.isNotEmpty)
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: textMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Options Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'notes':
                      onAddNote?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Task'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'notes',
                    child: Row(
                      children: [
                        Icon(Icons.note_add_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Notes'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
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
