import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phase_model.dart';
import '../models/task_model.dart';
import '../models/project_model.dart';
import '../models/note_model.dart';

class DatabaseService {
  static const int currentSchemaVersion = 1;

  static const String phasesBoxName = 'taskflow_phases';
  static const String tasksBoxName = 'taskflow_tasks';
  static const String projectsBoxName = 'taskflow_projects';
  static const String notesBoxName = 'taskflow_notes';
  static const String metaBoxName = 'taskflow_meta';

  late Box _phasesBox;
  late Box _tasksBox;
  late Box _projectsBox;
  late Box _notesBox;
  late Box _metaBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init({bool isTest = false}) async {
    if (_isInitialized) return;

    if (!isTest) {
      await Hive.initFlutter();
    }

    _phasesBox = await Hive.openBox(phasesBoxName);
    _tasksBox = await Hive.openBox(tasksBoxName);
    _projectsBox = await Hive.openBox(projectsBoxName);
    _notesBox = await Hive.openBox(notesBoxName);
    _metaBox = await Hive.openBox(metaBoxName);

    await _checkAndPerformMigrations();
    _isInitialized = true;
  }

  Future<void> _checkAndPerformMigrations() async {
    final storedVersion = _metaBox.get('schema_version', defaultValue: 0) as int;
    if (storedVersion < currentSchemaVersion) {
      debugPrint('Migrating database from version $storedVersion to $currentSchemaVersion');
      // Migration logic for future versions:
      // if (storedVersion == 0) { ... }
      await _metaBox.put('schema_version', currentSchemaVersion);
    }
  }

  // --- Phase Operations ---
  List<Phase> getAllPhases() {
    final list = <Phase>[];
    for (var key in _phasesBox.keys) {
      final raw = _phasesBox.get(key);
      if (raw != null) {
        if (raw is Map) {
          list.add(Phase.fromJson(Map<String, dynamic>.from(raw)));
        } else if (raw is String) {
          list.add(Phase.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        }
      }
    }
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> savePhase(Phase phase) async {
    await _phasesBox.put(phase.id, phase.toJson());
  }

  Future<void> saveAllPhases(List<Phase> phases) async {
    final map = <String, dynamic>{};
    for (var p in phases) {
      map[p.id] = p.toJson();
    }
    await _phasesBox.putAll(map);
  }

  Future<void> deletePhase(String id) async {
    await _phasesBox.delete(id);
    // Also delete associated tasks and projects
    final allTasks = getAllTasks();
    for (var t in allTasks) {
      if (t.phaseId == id) {
        await _tasksBox.delete(t.id);
      }
    }
    final allProjects = getAllProjects();
    for (var p in allProjects) {
      if (p.phaseId == id) {
        await _projectsBox.delete(p.id);
      }
    }
  }

  // --- Task Operations ---
  List<Task> getAllTasks() {
    final list = <Task>[];
    for (var key in _tasksBox.keys) {
      final raw = _tasksBox.get(key);
      if (raw != null) {
        if (raw is Map) {
          list.add(Task.fromJson(Map<String, dynamic>.from(raw)));
        } else if (raw is String) {
          list.add(Task.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        }
      }
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task.toJson());
  }

  Future<void> saveAllTasks(List<Task> tasks) async {
    final map = <String, dynamic>{};
    for (var t in tasks) {
      map[t.id] = t.toJson();
    }
    await _tasksBox.putAll(map);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  // --- Project Operations ---
  List<Project> getAllProjects() {
    final list = <Project>[];
    for (var key in _projectsBox.keys) {
      final raw = _projectsBox.get(key);
      if (raw != null) {
        if (raw is Map) {
          list.add(Project.fromJson(Map<String, dynamic>.from(raw)));
        } else if (raw is String) {
          list.add(Project.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        }
      }
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> saveProject(Project project) async {
    await _projectsBox.put(project.id, project.toJson());
  }

  Future<void> saveAllProjects(List<Project> projects) async {
    final map = <String, dynamic>{};
    for (var p in projects) {
      map[p.id] = p.toJson();
    }
    await _projectsBox.putAll(map);
  }

  Future<void> deleteProject(String id) async {
    await _projectsBox.delete(id);
  }

  // --- Note Operations ---
  List<Note> getAllNotes() {
    final list = <Note>[];
    for (var key in _notesBox.keys) {
      final raw = _notesBox.get(key);
      if (raw != null) {
        if (raw is Map) {
          list.add(Note.fromJson(Map<String, dynamic>.from(raw)));
        } else if (raw is String) {
          list.add(Note.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        }
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  // --- JSON Backup and Restore ---
  Map<String, dynamic> exportToJson() {
    return {
      'app': 'TaskFlow',
      'version': '1.0.0',
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'phases': getAllPhases().map((p) => p.toJson()).toList(),
      'tasks': getAllTasks().map((t) => t.toJson()).toList(),
      'projects': getAllProjects().map((p) => p.toJson()).toList(),
      'notes': getAllNotes().map((n) => n.toJson()).toList(),
    };
  }

  Future<void> importFromJson(Map<String, dynamic> data) async {
    if (data['phases'] is List) {
      final phases = (data['phases'] as List)
          .map((p) => Phase.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      await saveAllPhases(phases);
    }

    if (data['tasks'] is List) {
      final tasks = (data['tasks'] as List)
          .map((t) => Task.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();
      await saveAllTasks(tasks);
    }

    if (data['projects'] is List) {
      final projects = (data['projects'] as List)
          .map((p) => Project.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      await saveAllProjects(projects);
    }

    if (data['notes'] is List) {
      final notes = (data['notes'] as List)
          .map((n) => Note.fromJson(Map<String, dynamic>.from(n as Map)))
          .toList();
      for (var n in notes) {
        await saveNote(n);
      }
    }
  }

  // --- Reset Application ---
  Future<void> resetAllData() async {
    await _phasesBox.clear();
    await _tasksBox.clear();
    await _projectsBox.clear();
    await _notesBox.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('daily_learning_goal');
    await prefs.remove('notifications_enabled');
    await prefs.remove('notification_hour');
    await prefs.remove('notification_minute');
  }

  Future<void> clearCompletedTasks() async {
    final allTasks = getAllTasks();
    for (var t in allTasks) {
      if (t.isCompleted) {
        await _tasksBox.delete(t.id);
      }
    }
  }
}

