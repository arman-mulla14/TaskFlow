import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'project_detail_sheet.dart';
import 'project_edit_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _statusFilter = 'all'; // 'all', 'inProgress', 'completed', 'pending'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final projects = appState.projects;
    final phases = appState.phases;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final completedCount = projects.where((p) => p.isCompleted).length;
    final inProgressCount = projects.where((p) => p.status == ProjectStatus.inProgress).length;

    final filteredProjects = projects.where((p) {
      if (_statusFilter == 'inProgress') return p.status == ProjectStatus.inProgress;
      if (_statusFilter == 'completed') return p.status == ProjectStatus.completed;
      if (_statusFilter == 'pending') return p.status == ProjectStatus.pending;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Projects'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${projects.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Progress ($inProgressCount)', 'inProgress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed ($completedCount)', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Pending (${projects.length - completedCount - inProgressCount})', 'pending'),
                ],
              ),
            ),
          ),
          const Divider(),

          // Project List
          Expanded(
            child: filteredProjects.isEmpty
                ? EmptyState(
                    icon: Icons.rocket_launch_outlined,
                    title: 'No Mini Projects Found',
                    subtitle: projects.isEmpty
                        ? 'Mini projects from imported roadmaps will appear here, or create a project now!'
                        : 'No projects match the selected filter.',
                    buttonLabel: projects.isEmpty ? 'Create First Project' : null,
                    onButtonPressed: projects.isEmpty ? () => _addProject(context, appState) : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                    itemCount: filteredProjects.length,
                    itemBuilder: (ctx, i) {
                      final project = filteredProjects[i];
                      final phase = phases.where((p) => p.id == project.phaseId).firstOrNull;
                      final progress = project.checklistProgress;
                      final percentage = (progress * 100).toInt();

                      return Card(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => ProjectDetailSheet.show(context, project),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Title + Status + More Menu
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (phase != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              phase.title,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primaryAccentLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      status: project.status == ProjectStatus.completed
                                          ? TaskStatus.completed
                                          : project.status == ProjectStatus.inProgress
                                              ? TaskStatus.inProgress
                                              : TaskStatus.pending,
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, size: 18, color: textMuted),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          final updated = await ProjectEditDialog.show(
                                            context,
                                            project: project,
                                          );
                                          if (updated != null && context.mounted) {
                                            await appState.saveProject(updated);
                                          }
                                        } else if (val == 'delete') {
                                          final confirm = await ConfirmDialog.show(
                                            context: context,
                                            title: 'Delete Project',
                                            message:
                                                'Are you sure you want to delete "${project.title}"?',
                                            confirmLabel: 'Delete',
                                            isDestructive: true,
                                          );
                                          if (confirm && context.mounted) {
                                            await appState.deleteProject(project.id);
                                          }
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete',
                                              style: TextStyle(color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (project.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    project.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, color: textMuted),
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor:
                                        isDark ? AppColors.darkCard : Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.secondaryAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${project.completedChecklistCount} of ${project.totalChecklistCount} tasks completed',
                                      style: TextStyle(fontSize: 11.5, color: textMuted),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryAccent,
                                      ),
                                    ),
                                  ],
                                ),

                                // Preview top 3 checklist items
                                if (project.checklist.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  ...project.checklist.take(3).map((item) {
                                    return InkWell(
                                      onTap: () {
                                        appState.toggleProjectChecklistItem(project.id, item.id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Checkbox(
                                                value: item.isCompleted,
                                                onChanged: (_) {
                                                  appState.toggleProjectChecklistItem(
                                                      project.id, item.id);
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  decoration: item.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: item.isCompleted ? textMuted : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (project.checklist.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '+${project.checklist.length - 3} more subtasks...',
                                        style: TextStyle(fontSize: 11, color: textMuted),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProject(context, appState),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primaryAccent : null,
      ),
    );
  }

  Future<void> _addProject(BuildContext context, AppStateProvider appState) async {
    final newProject = await ProjectEditDialog.show(context);
    if (newProject != null) {
      await appState.saveProject(newProject);
    }
  }
}
