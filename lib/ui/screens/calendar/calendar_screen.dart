import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';
import '../tasks/task_detail_sheet.dart';
import '../tasks/task_edit_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final allTasks = appState.tasks;
    final phases = appState.phases;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Filter tasks for selected date
    final dateTasks = allTasks.where((t) {
      if (t.dueDate != null) {
        return t.dueDate!.year == _selectedDate.year &&
            t.dueDate!.month == _selectedDate.month &&
            t.dueDate!.day == _selectedDate.day;
      }
      if (t.isCompleted && t.completedAt != null) {
        return t.completedAt!.year == _selectedDate.year &&
            t.completedAt!.month == _selectedDate.month &&
            t.completedAt!.day == _selectedDate.day;
      }
      return false;
    }).toList();

    // Overdue tasks
    final overdueTasks = appState.overdueTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule & Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Schedule Task',
            onPressed: () => _scheduleNewTask(context, appState),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Overdue Warning Banner if any
          if (overdueTasks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${overdueTasks.length} task(s) overdue! Tap to review.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showOverdueSheet(context, overdueTasks, phases, appState),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 14-Day Horizontal Date Carousel
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 28,
              itemBuilder: (ctx, i) {
                final day = DateTime.now().subtract(const Duration(days: 7)).add(Duration(days: i));
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isToday = DateFormatter.isToday(day);

                // Check how many tasks due or done on this day
                final hasTasks = allTasks.any((t) =>
                    (t.dueDate != null &&
                        t.dueDate!.year == day.year &&
                        t.dueDate!.month == day.month &&
                        t.dueDate!.day == day.day) ||
                    (t.isCompleted &&
                        t.completedAt != null &&
                        t.completedAt!.year == day.year &&
                        t.completedAt!.month == day.month &&
                        t.completedAt!.day == day.day));

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : isToday
                              ? AppColors.primaryAccent.withOpacity(0.15)
                              : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryAccent
                            : isToday
                                ? AppColors.primaryAccent.withOpacity(0.4)
                                : Theme.of(context).dividerTheme.color ??
                                    Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(day),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.primaryAccent
                                    : textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.primaryAccent
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasTasks)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : AppColors.secondaryAccent,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Date Heading + Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.isToday(_selectedDate)
                    ? "Today's Agenda (${DateFormat('MMMM d').format(_selectedDate)})"
                    : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${dateTasks.length} Task${dateTasks.length == 1 ? "" : "s"}',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tasks on selected date
          if (dateTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: EmptyState(
                icon: Icons.event_available_outlined,
                title: 'No tasks scheduled',
                subtitle:
                    'No tasks are due or completed on this date. You can assign existing tasks or schedule a new one.',
                buttonLabel: 'Schedule Task for Date',
                onButtonPressed: () => _scheduleNewTask(context, appState),
              ),
            )
          else
            ...dateTasks.map((task) {
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
            }),
        ],
      ),
    );
  }

  Future<void> _scheduleNewTask(BuildContext context, AppStateProvider appState) async {
    final newTask = await TaskEditDialog.show(context);
    if (newTask != null) {
      final scheduled = newTask.copyWith(dueDate: _selectedDate);
      await appState.saveTask(scheduled);
    }
  }

  void _showOverdueSheet(
    BuildContext context,
    List<Task> overdueTasks,
    List<dynamic> phases,
    AppStateProvider appState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.danger),
                const SizedBox(width: 8),
                const Text('Overdue Tasks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: overdueTasks.map((task) {
                  return TaskTile(
                    task: task,
                    onCheckboxChanged: (_) => appState.toggleTaskCompletion(task.id),
                    onTap: () => TaskDetailSheet.show(context, task),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
