import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';
import 'task_detail_sheet.dart';
import 'task_edit_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'pending', 'inProgress', 'completed'
  String? _phaseFilter; // null = all phases
  TaskPriority? _priorityFilter; // null = all priorities

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final phases = appState.phases;
    final allTasks = appState.tasks;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Filter tasks
    final filteredTasks = allTasks.where((task) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        final matchNotes = task.notes.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchNotes) return false;
      }

      // 2. Status Filter
      if (_statusFilter == 'pending' && task.status != TaskStatus.pending) return false;
      if (_statusFilter == 'inProgress' && task.status != TaskStatus.inProgress) return false;
      if (_statusFilter == 'completed' && task.status != TaskStatus.completed) return false;

      // 3. Phase Filter
      if (_phaseFilter != null && task.phaseId != _phaseFilter) return false;

      // 4. Priority Filter
      if (_priorityFilter != null && task.priority != _priorityFilter) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Topics'),
        actions: [
          // Bulk Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Bulk Actions',
            onSelected: (val) async {
              if (val == 'complete_all') {
                final confirm = await ConfirmDialog.show(
                  context: context,
                  title: 'Complete All Visible',
                  message: 'Mark all ${filteredTasks.length} visible tasks as completed?',
                  confirmLabel: 'Mark Completed',
                );
                if (confirm && context.mounted) {
                  await appState.bulkCompleteTasks(
                    filteredTasks.map((t) => t.id).toList(),
                    true,
                  );
                }
              } else if (val == 'uncomplete_all') {
                await appState.bulkCompleteTasks(
                  filteredTasks.map((t) => t.id).toList(),
                  false,
                );
              } else if (val == 'clear_completed') {
                final confirm = await ConfirmDialog.show(
                  context: context,
                  title: 'Clear Completed Tasks',
                  message: 'Permanently remove all completed tasks from database?',
                  confirmLabel: 'Clear',
                  isDestructive: true,
                );
                if (confirm && context.mounted) {
                  await appState.clearCompletedTasks();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'complete_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 18),
                    SizedBox(width: 8),
                    Text('Mark Visible Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'uncomplete_all',
                child: Row(
                  children: [
                    Icon(Icons.remove_done, size: 18),
                    SizedBox(width: 8),
                    Text('Unmark Visible'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Clear All Completed', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks, topics, or notes...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('All (${allTasks.length})', 'all'),
                      const SizedBox(width: 6),
                      _buildStatusChip(
                        'Pending (${appState.pendingTasksCount})',
                        'pending',
                      ),
                      const SizedBox(width: 6),
                      _buildStatusChip(
                        'In Progress (${appState.inProgressTasksCount})',
                        'inProgress',
                      ),
                      const SizedBox(width: 6),
                      _buildStatusChip(
                        'Completed (${appState.completedTasksCount})',
                        'completed',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary Filter Row (Phase & Priority dropdowns)
                Row(
                  children: [
                    // Phase Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _phaseFilter,
                            isExpanded: true,
                            hint: Text('All Phases',
                                style: TextStyle(fontSize: 12, color: textMuted)),
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Phases', style: TextStyle(fontSize: 12)),
                              ),
                              ...phases.map((p) => DropdownMenuItem<String?>(
                                    value: p.id,
                                    child: Text(
                                      p.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _phaseFilter = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Priority Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskPriority?>(
                            value: _priorityFilter,
                            isExpanded: true,
                            hint: Text('All Priorities',
                                style: TextStyle(fontSize: 12, color: textMuted)),
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            items: [
                              const DropdownMenuItem<TaskPriority?>(
                                value: null,
                                child: Text('All Priorities', style: TextStyle(fontSize: 12)),
                              ),
                              ...TaskPriority.values.map((p) => DropdownMenuItem<TaskPriority?>(
                                    value: p,
                                    child: Text(p.label, style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _priorityFilter = val),
                          ),
                        ),
                      ),
                    ),

                    if (_phaseFilter != null || _priorityFilter != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_off, size: 18),
                        tooltip: 'Reset Filters',
                        onPressed: () {
                          setState(() {
                            _phaseFilter = null;
                            _priorityFilter = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Task List
          Expanded(
            child: filteredTasks.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching tasks found',
                    subtitle: allTasks.isEmpty
                        ? 'No tasks created yet. Paste a learning roadmap or add a task.'
                        : 'Try adjusting your search query or filters.',
                    buttonLabel: allTasks.isEmpty ? 'Add First Task' : null,
                    onButtonPressed: allTasks.isEmpty ? () => _addNewTask(context, appState) : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (ctx, i) {
                      final task = filteredTasks[i];
                      final phase = phases.where((p) => p.id == task.phaseId).firstOrNull;

                      return TaskTile(
                        task: task,
                        phaseName: phase?.title,
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
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewTask(context, appState),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
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

  Future<void> _addNewTask(BuildContext context, AppStateProvider appState) async {
    final newTask = await TaskEditDialog.show(context, initialPhaseId: _phaseFilter);
    if (newTask != null) {
      await appState.saveTask(newTask);
    }
  }
}
