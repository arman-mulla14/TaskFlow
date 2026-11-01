import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_edit_dialog.dart';

class TaskDetailSheet extends StatelessWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TaskDetailSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Fetch the freshest instance of this task
    final currentTask = appState.tasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );

    final phase = appState.phases.where((p) => p.id == currentTask.phaseId).firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Status & Priority Row
            Row(
              children: [
                StatusBadge(status: currentTask.status),
                const SizedBox(width: 8),
                PriorityBadge(priority: currentTask.priority),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final updated = await TaskEditDialog.show(context, task: currentTask);
                    if (updated != null && context.mounted) {
                      await appState.saveTask(updated);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                  onPressed: () async {
                    final confirm = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Task',
                      message: 'Are you sure you want to delete "${currentTask.title}"?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirm && context.mounted) {
                      Navigator.of(context).pop();
                      await appState.deleteTask(currentTask.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Interactive Checkbox + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: currentTask.isCompleted,
                    onChanged: (_) => appState.toggleTaskCompletion(currentTask.id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentTask.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: currentTask.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Phase Tag
            if (phase != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_outlined, size: 14, color: AppColors.primaryAccent),
                    const SizedBox(width: 6),
                    Text(
                      phase.title,
                      style: const TextStyle(
                        color: AppColors.primaryAccentLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Description
            if (currentTask.description.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentTask.description,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Due Date & Completion Date Info
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.event,
                    label: 'Due Date',
                    value: currentTask.dueDate != null
                        ? DateFormatter.formatMedium(currentTask.dueDate)
                        : 'No deadline',
                  ),
                ),
                if (currentTask.completedAt != null)
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.check_circle_outline,
                      label: 'Completed On',
                      value: DateFormatter.formatMedium(currentTask.completedAt),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes Section
            Text(
              'Personal Notes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Text(
                currentTask.notes.isNotEmpty
                    ? currentTask.notes
                    : 'No notes added yet. Tap edit to write notes or code snippets.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: currentTask.notes.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: currentTask.notes.isEmpty ? textMuted : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryAccent),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
