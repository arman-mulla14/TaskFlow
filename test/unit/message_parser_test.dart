import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/services/message_parser_service.dart';
import 'package:taskflow/data/models/task_model.dart';

void main() {
  late MessageParserService parser;

  setUp(() {
    parser = MessageParserService();
  });

  group('MessageParserService Tests', () {
    test('Scenario 1: Paste roadmap containing six phases and verify all identified', () {
      const input = '''
Phase 1 — Dart Programming (Weeks 1–2)
Foundation
1. Variables: var, final, const, dynamic
2. Data types: int, double, String, bool
Mini projects:
- Student Management System
- Banking System

Phase 2 — Flutter Fundamentals (Weeks 3–4)
1. Flutter architecture
2. Widget tree
- Personal Portfolio App

Phase 3: State Management (Weeks 5–6)
1. Provider basics
2. ChangeNotifier

Phase 4 - Local Database (Weeks 7–8)
1. Hive initialization
2. Box operations

Phase 5: Networking & APIs (Weeks 9–10)
1. HTTP requests
2. JSON serialization

Phase 6: Deployment & Release (Weeks 11–12)
1. App bundle build
2. Release signing
''';

      final result = parser.parseRoadmap(input);

      expect(result.phases.length, equals(6));
      expect(result.phases[0].title, contains('Phase 1 — Dart Programming'));
      expect(result.phases[0].weekDuration, equals('Weeks 1–2'));
      expect(result.phases[0].description, equals('Foundation'));
      expect(result.phases[0].tasks.length, equals(2));
      expect(result.phases[0].projects.length, equals(2));
      expect(result.phases[0].projects[0].title, equals('Student Management System'));

      expect(result.phases[1].title, contains('Phase 2 — Flutter Fundamentals'));
      expect(result.phases[1].weekDuration, equals('Weeks 3–4'));

      expect(result.phases[2].title, contains('Phase 3 — State Management'));
      expect(result.phases[3].title, contains('Phase 4 — Local Database'));
      expect(result.phases[4].title, contains('Phase 5 — Networking & APIs'));
      expect(result.phases[5].title, contains('Phase 6 — Deployment & Release'));
      expect(result.phases[5].weekDuration, equals('Weeks 11–12'));
    });

    test('Scenario 2: Correctly extracts numbered tasks and bullet points', () {
      const input = '''
Phase 1: Basic Topics
1. Task One: Description 1
2) Task Two: Description 2
[3] Task Three
- Bullet Task 1
* Bullet Task 2
• Bullet Task 3
+ Bullet Task 4
''';

      final result = parser.parseRoadmap(input);

      expect(result.phases.length, equals(1));
      final tasks = result.phases[0].tasks;
      expect(tasks.length, equals(7));

      expect(tasks[0].title, equals('Task One'));
      expect(tasks[0].description, equals('Description 1'));

      expect(tasks[1].title, equals('Task Two'));
      expect(tasks[1].description, equals('Description 2'));

      expect(tasks[2].title, equals('Task Three'));
      expect(tasks[3].title, equals('Bullet Task 1'));
      expect(tasks[4].title, equals('Bullet Task 2'));
      expect(tasks[5].title, equals('Bullet Task 3'));
      expect(tasks[6].title, equals('Bullet Task 4'));
    });

    test('Scenario 3: Preserves mini projects and sub-checklist items', () {
      const input = '''
Phase 1 — Project Work
Mini projects:
- Student Management System
    * Create student model
    * Add student
    * Display students
- Banking System
    * Deposit money
    * Withdraw money
''';

      final result = parser.parseRoadmap(input);
      expect(result.phases.length, equals(1));
      final projects = result.phases[0].projects;
      expect(projects.length, equals(2));

      expect(projects[0].title, equals('Student Management System'));
      expect(projects[0].checklist.length, equals(3));
      expect(projects[0].checklist[0], equals('Create student model'));

      expect(projects[1].title, equals('Banking System'));
      expect(projects[1].checklist.length, equals(2));
      expect(projects[1].checklist[1], equals('Withdraw money'));
    });

    test('Scenario 4: Handles input without explicit phase heading', () {
      const input = '''
1. Install Flutter SDK
2. Setup Android Studio
- Run flutter doctor
''';

      final result = parser.parseRoadmap(input);
      expect(result.phases.length, equals(1));
      expect(result.phases[0].tasks.length, equals(3));
    });

    test('Scenario 5: Preserves unparsed text and does not discard it', () {
      const input = '''
Phase 1: Intro
1. First Task
Random unparsed note or link: https://flutter.dev
Important announcement regarding exam dates!
''';

      final result = parser.parseRoadmap(input);
      expect(result.phases.length, equals(1));
      expect(result.phases[0].tasks.length, equals(1));
      expect(result.unparsedLines.length, equals(2));
      expect(result.unparsedLines[0], contains('Random unparsed note'));
      expect(result.unparsedLines[1], contains('Important announcement'));
    });

    test('Scenario 6: Inconsistent spacing and priority tags', () {
      const input = '''

   Phase 1 - Testing Priorities (Duration: 3 weeks)   

   1. Variables [High]
   2. Functions [Low]
   3. Normal Task

''';

      final result = parser.parseRoadmap(input);
      expect(result.phases.length, equals(1));
      expect(result.phases[0].weekDuration, contains('3 weeks'));
      final tasks = result.phases[0].tasks;
      expect(tasks.length, equals(3));
      expect(tasks[0].priority, equals(TaskPriority.high));
      expect(tasks[1].priority, equals(TaskPriority.low));
      expect(tasks[2].priority, equals(TaskPriority.medium));
    });

    test('Scenario 7: Empty or whitespace-only input returns empty result', () {
      final result1 = parser.parseRoadmap('');
      expect(result1.phases, isEmpty);
      expect(result1.unparsedLines, isEmpty);

      final result2 = parser.parseRoadmap('   \n\n   \t  \n');
      expect(result2.phases, isEmpty);
      expect(result2.unparsedLines, isEmpty);
    });
  });
}
