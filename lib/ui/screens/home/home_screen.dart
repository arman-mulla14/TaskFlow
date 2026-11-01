import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/app_state_provider.dart';
import '../../widgets/task_tile.dart';
import '../import/import_screen.dart';
import '../tasks/task_detail_sheet.dart';
import '../tasks/task_edit_dialog.dart';
import '../phases/phases_screen.dart';
import '../phases/phase_detail_screen.dart';
import 'widgets/circular_progress_card.dart';
import 'widgets/streak_card.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final phases = appState.phases;
    final streak = appState.streakResult;
    final todayTasks = appState.todayTasks;
    final upcomingDeadlines = appState.upcomingDeadlines;
    final recentTasks = appState.recentlyUpdatedTasks;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'All Phases',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhasesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Tasks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.reloadData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Tagline subheader
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAccentLight,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),

            // Prominent "Import Tasks" Banner Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C5CFC), Color(0xFF5333DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ImportScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Roadmap Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Paste your learning plan & auto-generate tasks',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overall Circular Progress Card
            CircularProgressCard(
              progress: appState.overallProgress,
              totalTasks: appState.totalTasksCount,
              completedTasks: appState.completedTasksCount,
              pendingTasks: appState.pendingTasksCount + appState.inProgressTasksCount,
            ),
            const SizedBox(height: 12),

            // Streak & Daily Goal Card
            StreakCard(
              currentStreak: streak.currentStreak,
              bestStreak: streak.bestStreak,
              todayCompleted: appState.todayCompletedCount,
              dailyGoal: appState.dailyGoal,
            ),
            const SizedBox(height: 18),

            // Metric Counters Grid (4 items)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Phases',
                    value: '${appState.totalPhasesCount}',
                    icon: Icons.layers_outlined,
                    iconColor: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Total Tasks',
                    value: '${appState.totalTasksCount}',
                    icon: Icons.checklist,
                    iconColor: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Completed',
                    value: '${appState.completedTasksCount}',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.secondaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    context: context,
                    label: 'Remaining',
                    value: '${appState.pendingTasksCount}',
                    icon: Icons.pending_outlined,
                    iconColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Learning Phases Carousel / Section
            if (phases.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learning Phases',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PhasesScreen()),
                      );
                    },
                    child: const Text('View All', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: phases.length,
                  itemBuilder: (ctx, i) {
                    final phase = phases[i];
                    final pProgress = appState.getPhaseProgress(phase.id);
                    final pTotal = appState.getPhaseTasksCount(phase.id);
                    final pDone = appState.getPhaseCompletedCount(phase.id);

                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PhaseDetailScreen(phase: phase),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        phase.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                    ),
                                    Text(
                                      '${(pProgress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                if (phase.weekDuration.isNotEmpty)
                                  Text(
                                    phase.weekDuration,
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pProgress,
                                        minHeight: 6,
                                        backgroundColor:
                                            isDark ? AppColors.darkCard : Colors.grey.shade200,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.secondaryAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$pDone / $pTotal completed',
                                      style: TextStyle(fontSize: 11, color: textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Today's Tasks
            if (todayTasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.today, size: 18, color: AppColors.primaryAccent),
                      SizedBox(width: 8),
                      Text(
                        "Today's Tasks",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length} Done',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...todayTasks.map((task) {
                final phase = phases.where((p) => p.id == task.phaseId).firstOrNull;
                return TaskTile(
                  task: task,
                  phaseName: phase?.title,
                  onCheckboxChanged: (_) => appState.toggleTaskCompletion(task.id),
                  onTap: () => TaskDetailSheet.show(context, task),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Upcoming Deadlines
            if (upcomingDeadlines.isNotEmpty) ...[
              const Text(
                'Upcoming Deadlines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...upcomingDeadlines.take(4).map((task) {
                final phase = phases.where((p) => p.id == task.phaseId).firstOrNull;
                return TaskTile(
                  task: task,
                  phaseName: phase?.title,
                  onCheckboxChanged: (_) => appState.toggleTaskCompletion(task.id),
                  onTap: () => TaskDetailSheet.show(context, task),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Recently Updated Tasks
            if (recentTasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Tasks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab?.call(1), // Jump to Tasks Tab
                    child: const Text('View All', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...recentTasks.take(5).map((task) {
                final phase = phases.where((p) => p.id == task.phaseId).firstOrNull;
                return TaskTile(
                  task: task,
                  phaseName: phase?.title,
                  onCheckboxChanged: (_) => appState.toggleTaskCompletion(task.id),
                  onTap: () => TaskDetailSheet.show(context, task),
                );
              }),
            ],

            // If empty database, show encouraging starter prompt
            if (appState.totalTasksCount == 0) ...[
              const SizedBox(height: 10),
              Card(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 48, color: AppColors.primaryAccent),
                      const SizedBox(height: 12),
                      const Text(
                        'No Learning Roadmap Loaded',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get started by pasting your syllabus or learning goals into the converter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ImportScreen()),
                          );
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('Import Roadmap Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newTask = await TaskEditDialog.show(context);
          if (newTask != null && context.mounted) {
            await appState.saveTask(newTask);
          }
        },
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
