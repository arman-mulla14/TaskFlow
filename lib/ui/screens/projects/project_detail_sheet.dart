import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/project_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import 'project_edit_dialog.dart';

class ProjectDetailSheet extends StatelessWidget {
  final Project project;

  const ProjectDetailSheet({super.key, required this.project});

  static Future<void> show(BuildContext context, Project project) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProjectDetailSheet(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final currentProject = appState.projects.firstWhere(
      (p) => p.id == project.id,
      orElse: () => project,
    );

    final phase = appState.phases.where((p) => p.id == currentProject.phaseId).firstOrNull;

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

            // Top Status & Actions Row
            Row(
              children: [
                StatusBadge(
                  status: currentProject.status,
                ),
                if (phase != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      phase.title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryAccentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final updated = await ProjectEditDialog.show(context, project: currentProject);
                    if (updated != null && context.mounted) {
                      await appState.saveProject(updated);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                  onPressed: () async {
                    final confirm = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Mini Project',
                      message: 'Are you sure you want to delete "${currentProject.title}"?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirm && context.mounted) {
                      Navigator.of(context).pop();
                      await appState.deleteProject(currentProject.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              currentProject.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            if (currentProject.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                currentProject.description,
                style: TextStyle(fontSize: 13.5, color: textMuted, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentProject.checklistProgress,
                minHeight: 8,
                backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentProject.completedChecklistCount} of ${currentProject.totalChecklistCount} subtasks complete',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                Text(
                  '${(currentProject.checklistProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Checklist section
            const Text(
              'Implementation Tasks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            if (currentProject.checklist.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No checklist subtasks. Tap edit to add subtasks.',
                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: textMuted),
                ),
              )
            else
              ...currentProject.checklist.map((item) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (_) {
                        appState.toggleProjectChecklistItem(currentProject.id, item.id);
                      },
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        color: item.isCompleted ? textMuted : null,
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 18),

            // Notes
            if (currentProject.notes.isNotEmpty) ...[
              const Text(
                'Project Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(currentProject.notes, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 16),
            ],

            // Dates
            Text(
              'Created: ${DateFormatter.formatMedium(currentProject.createdAt)}',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
