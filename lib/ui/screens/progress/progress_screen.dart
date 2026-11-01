import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/app_state_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _timeRange = '7days'; // 'today', '7days', '30days', 'all'

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final tasks = appState.tasks;
    final phases = appState.phases;
    final projects = appState.projects;
    final streak = appState.streakResult;

    final completedProjects = projects.where((p) => p.isCompleted).length;

    // Filter tasks based on selected range
    final filteredTasks = _filterTasksByRange(tasks, _timeRange);
    final completedCount = filteredTasks.where((t) => t.isCompleted).length;
    final totalRangeTasks = filteredTasks.length;
    final progressPct = totalRangeTasks > 0
        ? (completedCount / totalRangeTasks * 100).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Time Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRangeChip('Today', 'today'),
                const SizedBox(width: 8),
                _buildRangeChip('Last 7 Days', '7days'),
                const SizedBox(width: 8),
                _buildRangeChip('Last 30 Days', '30days'),
                const SizedBox(width: 8),
                _buildRangeChip('All Time', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Overview Metrics Hero Card
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Completion Rate',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$progressPct%',
                          style: const TextStyle(
                            color: AppColors.secondaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalRangeTasks > 0 ? completedCount / totalRangeTasks : 0.0,
                      minHeight: 10,
                      backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Completed', '$completedCount', AppColors.secondaryAccent),
                      _buildMetricItem(
                          'Pending', '${totalRangeTasks - completedCount}', AppColors.warning),
                      _buildMetricItem('Total in Range', '$totalRangeTasks', textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Streaks & Highlights Grid
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  title: 'Current Streak',
                  value: '${streak.currentStreak} Days',
                  icon: Icons.local_fire_department,
                  iconColor: const Color(0xFFFF9800),
                  isDark: isDark,
                  cardBg: cardBg,
                  textMuted: textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStreakCard(
                  title: 'Best Streak',
                  value: '${streak.bestStreak} Days',
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.warning,
                  isDark: isDark,
                  cardBg: cardBg,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  title: 'Learning Days',
                  value: '${streak.totalLearningDays} Days',
                  icon: Icons.calendar_month_outlined,
                  iconColor: AppColors.info,
                  isDark: isDark,
                  cardBg: cardBg,
                  textMuted: textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStreakCard(
                  title: 'Mini Projects',
                  value: '$completedProjects / ${projects.length}',
                  icon: Icons.rocket_launch_outlined,
                  iconColor: AppColors.secondaryAccent,
                  isDark: isDark,
                  cardBg: cardBg,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Daily Task Completion Bar Chart (Real local data for past 7 days)
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Completed Tasks (Last 7 Days)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actual completed learning items per day',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 170,
                    child: _buildDailyBarChart(tasks, isDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cumulative Progress Trend Line Chart
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Velocity (Past Week)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cumulative task completion growth',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 170,
                    child: _buildWeeklyLineChart(tasks, isDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phase-wise Progress Breakdown
          Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phase-wise Learning Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mastery breakdown across roadmap phases',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (phases.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No phases available. Import a roadmap to see breakdown.',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ...phases.map((phase) {
                      final pProgress = appState.getPhaseProgress(phase.id);
                      final pTotal = appState.getPhaseTasksCount(phase.id);
                      final pDone = appState.getPhaseCompletedCount(phase.id);
                      final pPct = (pProgress * 100).toInt();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    phase.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$pPct% ($pDone/$pTotal)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondaryAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pProgress,
                                minHeight: 6,
                                backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.secondaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String label, String value) {
    final isSelected = _timeRange == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _timeRange = value),
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primaryAccent : null,
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStreakCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color cardBg,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 10.5, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Task> _filterTasksByRange(List<Task> tasks, String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == 'today') {
      return tasks.where((t) {
        if (t.isCompleted && t.completedAt != null) {
          final d = t.completedAt!;
          return d.year == today.year && d.month == today.month && d.day == today.day;
        }
        if (t.dueDate != null) {
          final d = t.dueDate!;
          return d.year == today.year && d.month == today.month && d.day == today.day;
        }
        return false;
      }).toList();
    } else if (range == '7days') {
      final start = today.subtract(const Duration(days: 6));
      return tasks.where((t) {
        final d = t.completedAt ?? t.createdAt;
        return !d.isBefore(start);
      }).toList();
    } else if (range == '30days') {
      final start = today.subtract(const Duration(days: 29));
      return tasks.where((t) {
        final d = t.completedAt ?? t.createdAt;
        return !d.isBefore(start);
      }).toList();
    }
    return tasks;
  }

  Widget _buildDailyBarChart(List<Task> tasks, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<BarChartGroupData> groups = [];
    final List<String> dayLabels = [];
    double maxY = 4;

    for (int i = 6; i >= 0; i--) {
      final targetDay = today.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(targetDay));

      final count = tasks.where((t) {
        if (!t.isCompleted || t.completedAt == null) return false;
        final d = t.completedAt!;
        return d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day;
      }).length;

      if (count.toDouble() > maxY) {
        maxY = count.toDouble() + 1;
      }

      final isCurrentDay = i == 0;
      groups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: isCurrentDay ? AppColors.secondaryAccent : AppColors.primaryAccent,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} tasks',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      dayLabels[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (maxY / 3).ceilToDouble().clamp(1.0, 10.0),
              getTitlesWidget: (val, meta) {
                return Text(
                  '${val.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 3).ceilToDouble().clamp(1.0, 10.0),
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  Widget _buildWeeklyLineChart(List<Task> tasks, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<FlSpot> spots = [];
    final List<String> dayLabels = [];
    int cumulative = 0;

    for (int i = 6; i >= 0; i--) {
      final targetDay = today.subtract(Duration(days: i));
      dayLabels.add(DateFormat('M/d').format(targetDay));

      final count = tasks.where((t) {
        if (!t.isCompleted || t.completedAt == null) return false;
        final d = t.completedAt!;
        return d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day;
      }).length;

      cumulative += count;
      spots.add(FlSpot((6 - i).toDouble(), cumulative.toDouble()));
    }

    final double maxY = (cumulative > 4 ? cumulative + 2 : 6).toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} tasks total',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 3).ceilToDouble().clamp(1.0, 10.0),
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 0.8,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      dayLabels[idx],
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (maxY / 3).ceilToDouble().clamp(1.0, 10.0),
              getTitlesWidget: (val, meta) {
                return Text(
                  '${val.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondaryAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondaryAccent.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
