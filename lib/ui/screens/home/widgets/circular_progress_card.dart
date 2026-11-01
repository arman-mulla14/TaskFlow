import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CircularProgressCard extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  const CircularProgressCard({
    super.key,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final percentage = (progress * 100).toInt();

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Circular Progress Indicator with glowing center
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Track
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 9,
                      color: isDark ? AppColors.darkCardElevated : Colors.grey.shade200,
                    ),
                  ),
                  // Progress Value Track
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
                        );
                      },
                    ),
                  ),
                  // Percentage text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Statistics column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Progress',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    label: 'Total Tasks',
                    value: '$totalTasks',
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    dotColor: AppColors.primaryAccent,
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    label: 'Completed',
                    value: '$completedTasks',
                    color: AppColors.secondaryAccent,
                    dotColor: AppColors.secondaryAccent,
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(
                    label: 'Remaining',
                    value: '$pendingTasks',
                    color: textMuted,
                    dotColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
    required Color dotColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
