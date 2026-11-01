import '../../data/models/task_model.dart';

class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final int totalLearningDays;

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalLearningDays,
  });
}

class StreakCalculator {
  static StreakResult calculate(List<Task> tasks) {
    final completedTasks = tasks.where((t) => t.isCompleted && t.completedAt != null).toList();
    if (completedTasks.isEmpty) {
      return const StreakResult(
        currentStreak: 0,
        bestStreak: 0,
        totalLearningDays: 0,
      );
    }

    // Extract unique completion days sorted ascending
    final Set<DateTime> uniqueDays = {};
    for (var t in completedTasks) {
      final d = t.completedAt!;
      uniqueDays.add(DateTime(d.year, d.month, d.day));
    }

    final sortedDays = uniqueDays.toList()..sort();
    final totalDays = sortedDays.length;

    // Calculate best streak
    int bestStreak = 1;
    int tempStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final prev = sortedDays[i - 1];
      final curr = sortedDays[i];
      final diff = curr.difference(prev).inDays;

      if (diff == 1) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else if (diff > 1) {
        tempStreak = 1;
      }
    }

    // Calculate current streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    if (sortedDays.contains(today)) {
      currentStreak = 1;
      var checkDay = today.subtract(const Duration(days: 1));
      while (sortedDays.contains(checkDay)) {
        currentStreak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    } else if (sortedDays.contains(yesterday)) {
      currentStreak = 1;
      var checkDay = yesterday.subtract(const Duration(days: 1));
      while (sortedDays.contains(checkDay)) {
        currentStreak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalLearningDays: totalDays,
    );
  }
}

