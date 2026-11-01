import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int todayCompleted;
  final int dailyGoal;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.todayCompleted,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Fire Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF9800),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Streak text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$currentStreak Day${currentStreak == 1 ? "" : "s"} Streak',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Best: $bestStreak)',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    todayCompleted >= dailyGoal
                        ? '🔥 Daily goal met ($todayCompleted/$dailyGoal completed)'
                        : 'Today: $todayCompleted of $dailyGoal tasks completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: todayCompleted >= dailyGoal ? AppColors.secondaryAccent : textMuted,
                      fontWeight: todayCompleted >= dailyGoal ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Daily goal progress mini ring
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: dailyGoal > 0 ? (todayCompleted / dailyGoal).clamp(0.0, 1.0) : 0,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    color: AppColors.secondaryAccent,
                    backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                  ),
                  Text(
                    '$todayCompleted',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
