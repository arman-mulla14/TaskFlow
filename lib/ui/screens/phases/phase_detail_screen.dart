import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/phase_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';
import '../tasks/task_detail_sheet.dart';
import '../tasks/task_edit_dialog.dart';
import 'phase_edit_dialog.dart';

class PhaseDetailScreen extends StatefulWidget {
  final Phase phase;

  const PhaseDetailScreen({super.key, required this.phase});

  @override
  State<PhaseDetailScreen> createState() => _PhaseDetailScreenState();
}

class _PhaseDetailScreenState extends State<PhaseDetailScreen> {
  String _filter = 'all'; // 'all', 'pending', 'completed'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Get current instance of phase
    final currentPhase = appState.phases.firstWhere(
      (p) => p.id == widget.phase.id,
      orElse: () => widget.phase,
    );

    final phaseTasks = appState.tasks.where((t) => t.phaseId == currentPhase.id).toList();
    final total = phaseTasks.length;
    final completed = phaseTasks.where((t) => t.isCompleted).length;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    final filteredTasks = phaseTasks.where((t) {
      if (_filter == 'pending') return !t.isCompleted;
      if (_filter == 'completed') return t.isCompleted;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPhase.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Phase',
            onPressed: () async {
              final updated = await PhaseEditDialog.show(context, phase: currentPhase);
              if (updated != null && context.mounted) {
                await appState.savePhase(updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Phase',
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context: context,
                title: 'Delete Phase',
                message:
                    'Are you sure you want to delete "${currentPhase.title}" and all its tasks?',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirm && context.mounted) {
                Navigator.of(context).pop();
                await appState.deletePhase(currentPhase.id);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Header Card with metrics & progress
          Card(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentPhase.weekDuration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentPhase.weekDuration,
                            style: const TextStyle(
                              color: AppColors.secondaryAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        '$percentage% Completed',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                    ],
                  ),
                  if (currentPhase.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentPhase.description,
                      style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$completed of $total tasks completed',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Segmented Row
          Row(
            children: [
              _buildFilterChip('All ($total)', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending (${total - completed})', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Done ($completed)', 'completed'),
            ],
          ),
          const SizedBox(height: 14),

          // Tasks List
          if (filteredTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: EmptyState(
                icon: Icons.checklist,
                title: 'No tasks found',
                subtitle: _filter == 'all'
                    ? 'No tasks in this phase yet. Tap + to add one.'
                    : 'No $_filter tasks in this phase.',
                buttonLabel: _filter == 'all' ? 'Add Task' : null,
                onButtonPressed: () => _addTask(context, appState, currentPhase.id),
              ),
            )
          else
            ...filteredTasks.map((task) {
              return TaskTile(
                task: task,
                phaseName: null,
                onCheckboxChanged: (_) => appState.toggleTaskCompletion(task.id),
                onTap: () => TaskDetailSheet.show(context, task),
                onEdit: () async {
                  final updated = await TaskEditDialog.show(context, task: task);
                  if (updated != null && context.mounted) {
                    await appState.saveTask(updated);
                  }
                },
                onDelete: () => appState.deleteTask(task.id),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(context, appState, currentPhase.id),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryAccent : null,
      ),
    );
  }

  Future<void> _addTask(BuildContext context, AppStateProvider appState, String phaseId) async {
    final newTask = await TaskEditDialog.show(context, initialPhaseId: phaseId);
    if (newTask != null) {
      await appState.saveTask(newTask);
    }
  }
}
