import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/utils/streak_calculator.dart';
import 'package:taskflow/data/models/task_model.dart';

void main() {
  group('StreakCalculator Tests', () {
    test('Empty tasks list returns 0 streak', () {
      final result = StreakCalculator.calculate([]);
      expect(result.currentStreak, equals(0));
      expect(result.bestStreak, equals(0));
      expect(result.totalLearningDays, equals(0));
    });

    test('Completed task today gives 1-day current streak', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: '1',
          phaseId: 'p1',
          title: 'Task 1',
          status: TaskStatus.completed,
          createdAt: now,
          completedAt: now,
        ),
      ];

      final result = StreakCalculator.calculate(tasks);
      expect(result.currentStreak, equals(1));
      expect(result.bestStreak, equals(1));
      expect(result.totalLearningDays, equals(1));
    });

    test('Consecutive completions over 3 days calculate 3-day streak', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final tasks = [
        Task(
          id: '1',
          phaseId: 'p1',
          title: 'Task 1',
          status: TaskStatus.completed,
          createdAt: twoDaysAgo,
          completedAt: twoDaysAgo,
        ),
        Task(
          id: '2',
          phaseId: 'p1',
          title: 'Task 2',
          status: TaskStatus.completed,
          createdAt: yesterday,
          completedAt: yesterday,
        ),
        Task(
          id: '3',
          phaseId: 'p1',
          title: 'Task 3',
          status: TaskStatus.completed,
          createdAt: today,
          completedAt: today,
        ),
      ];

      final result = StreakCalculator.calculate(tasks);
      expect(result.currentStreak, equals(3));
      expect(result.bestStreak, equals(3));
      expect(result.totalLearningDays, equals(3));
    });

    test('Completed yesterday keeps streak active even before today completion', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final tasks = [
        Task(
          id: '1',
          phaseId: 'p1',
          title: 'Task 1',
          status: TaskStatus.completed,
          createdAt: yesterday,
          completedAt: yesterday,
        ),
      ];

      final result = StreakCalculator.calculate(tasks);
      expect(result.currentStreak, equals(1));
    });

    test('Broken streak computes best streak correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fiveDaysAgo = today.subtract(const Duration(days: 5));
      final fourDaysAgo = today.subtract(const Duration(days: 4));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      // 3 consecutive days in the past, then gap, then today (1 day)
      final tasks = [
        Task(
          id: '1',
          phaseId: 'p1',
          title: 'Task 1',
          status: TaskStatus.completed,
          createdAt: fiveDaysAgo,
          completedAt: fiveDaysAgo,
        ),
        Task(
          id: '2',
          phaseId: 'p1',
          title: 'Task 2',
          status: TaskStatus.completed,
          createdAt: fourDaysAgo,
          completedAt: fourDaysAgo,
        ),
        Task(
          id: '3',
          phaseId: 'p1',
          title: 'Task 3',
          status: TaskStatus.completed,
          createdAt: threeDaysAgo,
          completedAt: threeDaysAgo,
        ),
        Task(
          id: '4',
          phaseId: 'p1',
          title: 'Task 4',
          status: TaskStatus.completed,
          createdAt: today,
          completedAt: today,
        ),
      ];

      final result = StreakCalculator.calculate(tasks);
      expect(result.currentStreak, equals(1));
      expect(result.bestStreak, equals(3));
      expect(result.totalLearningDays, equals(4));
    });
  });
}
