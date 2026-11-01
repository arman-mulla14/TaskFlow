import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:taskflow/data/models/phase_model.dart';
import 'package:taskflow/data/models/task_model.dart';
import 'package:taskflow/data/models/project_model.dart';
import 'package:taskflow/data/models/project_checklist_item_model.dart';
import 'package:taskflow/data/models/note_model.dart';
import 'package:taskflow/data/repositories/database_service.dart';
import 'package:taskflow/data/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late DatabaseService db;
  late BackupService backup;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('taskflow_test_');
    Hive.init(tempDir.path);

    db = DatabaseService();
    await db.init(isTest: true);
    backup = BackupService(db);
  });

  tearDown(() async {
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Database & Backup Tests', () {
    test('Phase CRUD Operations', () async {
      final now = DateTime.now();
      final phase = Phase(
        id: 'p1',
        title: 'Phase 1 - Dart',
        weekDuration: 'Weeks 1-2',
        description: 'Foundation',
        order: 1,
        createdAt: now,
      );

      await db.savePhase(phase);
      final list = db.getAllPhases();
      expect(list.length, equals(1));
      expect(list.first.title, equals('Phase 1 - Dart'));
      expect(list.first.weekDuration, equals('Weeks 1-2'));

      // Update Phase
      final updated = phase.copyWith(title: 'Phase 1 - Advanced Dart');
      await db.savePhase(updated);
      expect(db.getAllPhases().first.title, equals('Phase 1 - Advanced Dart'));

      // Delete Phase
      await db.deletePhase('p1');
      expect(db.getAllPhases(), isEmpty);
    });

    test('Task CRUD and Completion Flow', () async {
      final now = DateTime.now();
      final task = Task(
        id: 't1',
        phaseId: 'p1',
        title: 'Learn Variables',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        createdAt: now,
      );

      await db.saveTask(task);
      expect(db.getAllTasks().length, equals(1));
      expect(db.getAllTasks().first.isCompleted, isFalse);

      // Complete Task
      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
      );
      await db.saveTask(completedTask);
      expect(db.getAllTasks().first.isCompleted, isTrue);

      // Uncomplete Task
      final pendingAgain = completedTask.copyWith(
        status: TaskStatus.pending,
        clearCompletedAt: true,
      );
      await db.saveTask(pendingAgain);
      expect(db.getAllTasks().first.isCompleted, isFalse);
      expect(db.getAllTasks().first.completedAt, isNull);

      // Delete Task
      await db.deleteTask('t1');
      expect(db.getAllTasks(), isEmpty);
    });

    test('Project & Checklist Operations', () async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj1',
        title: 'Student Management System',
        phaseId: 'p1',
        checklist: [
          const ProjectChecklistItem(id: 'c1', projectId: 'proj1', title: 'Model', isCompleted: true),
          const ProjectChecklistItem(id: 'c2', projectId: 'proj1', title: 'UI', isCompleted: false),
        ],
        createdAt: now,
      );

      await db.saveProject(project);
      final retrieved = db.getAllProjects().first;
      expect(retrieved.title, equals('Student Management System'));
      expect(retrieved.checklist.length, equals(2));
      expect(retrieved.completedChecklistCount, equals(1));
      expect(retrieved.checklistProgress, equals(0.5));
    });

    test('Note CRUD Operations', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'n1',
        relatedEntityId: 'p1',
        entityType: 'phase',
        content: 'Remember to practice mixins',
        createdAt: now,
        updatedAt: now,
      );

      await db.saveNote(note);
      expect(db.getAllNotes().length, equals(1));
      expect(db.getAllNotes().first.content, contains('mixins'));

      await db.deleteNote('n1');
      expect(db.getAllNotes(), isEmpty);
    });

    test('Export and Restore Database Backup JSON', () async {
      final now = DateTime.now();
      final phase = Phase(id: 'p1', title: 'Phase 1', createdAt: now);
      final task = Task(id: 't1', phaseId: 'p1', title: 'Task 1', createdAt: now);
      final note = Note(id: 'n1', relatedEntityId: 't1', content: 'Note 1', createdAt: now, updatedAt: now);

      await db.savePhase(phase);
      await db.saveTask(task);
      await db.saveNote(note);

      final exportedJson = backup.exportToJsonString();
      expect(exportedJson, contains('TaskFlow'));
      expect(exportedJson, contains('Phase 1'));
      expect(exportedJson, contains('Task 1'));

      // Clear DB
      await db.resetAllData();
      expect(db.getAllPhases(), isEmpty);
      expect(db.getAllTasks(), isEmpty);
      expect(db.getAllNotes(), isEmpty);

      // Restore from JSON
      await backup.restoreFromJsonString(exportedJson);
      expect(db.getAllPhases().length, equals(1));
      expect(db.getAllTasks().length, equals(1));
      expect(db.getAllNotes().length, equals(1));
      expect(db.getAllPhases().first.title, equals('Phase 1'));
    });

    test('Clear Completed Tasks removes only completed items', () async {
      final now = DateTime.now();
      final t1 = Task(id: 't1', phaseId: 'p1', title: 'Done Task', status: TaskStatus.completed, createdAt: now);
      final t2 = Task(id: 't2', phaseId: 'p1', title: 'Pending Task', status: TaskStatus.pending, createdAt: now);

      await db.saveTask(t1);
      await db.saveTask(t2);
      expect(db.getAllTasks().length, equals(2));

      await db.clearCompletedTasks();
      final remaining = db.getAllTasks();
      expect(remaining.length, equals(1));
      expect(remaining.first.title, equals('Pending Task'));
    });

    test('Generate Progress Report contains formatted markdown', () async {
      final now = DateTime.now();
      final phase = Phase(id: 'p1', title: 'Flutter Basics', weekDuration: 'Weeks 1-2', createdAt: now);
      final task = Task(id: 't1', phaseId: 'p1', title: 'Widgets', status: TaskStatus.completed, createdAt: now);

      await db.savePhase(phase);
      await db.saveTask(task);

      final report = backup.generateProgressReport();
      expect(report, contains('# TaskFlow Learning Progress Report'));
      expect(report, contains('Flutter Basics'));
      expect(report, contains('Widgets'));
      expect(report, contains('[x] Widgets'));
    });
  });
}
