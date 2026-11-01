import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/phase_model.dart';
import '../data/models/task_model.dart';
import '../data/models/project_model.dart';
import '../data/models/project_checklist_item_model.dart';
import '../data/models/note_model.dart';
import '../data/models/parsed_import_result.dart';
import '../data/repositories/database_service.dart';
import '../core/utils/streak_calculator.dart';
import '../core/utils/date_formatter.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  static const _uuid = Uuid();
  static const String _prefDailyGoal = 'daily_learning_goal';

  List<Phase> _phases = [];
  List<Task> _tasks = [];
  List<Project> _projects = [];
  List<Note> _notes = [];

  int _dailyGoal = 3;
  bool _isLoading = true;

  AppStateProvider(this._db) {
    _loadAllData();
  }

  bool get isLoading => _isLoading;
  List<Phase> get phases => List.unmodifiable(_phases);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Note> get notes => List.unmodifiable(_notes);
  int get dailyGoal => _dailyGoal;

  // --- Statistics & Derived Getters ---
  int get totalPhasesCount => _phases.length;
  int get totalTasksCount => _tasks.length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasksCount => _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressTasksCount => _tasks.where((t) => t.status == TaskStatus.inProgress).length;

  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    return (completedTasksCount / totalTasksCount).clamp(0.0, 1.0);
  }

  int get overallProgressPercentage => (overallProgress * 100).round();

  List<Task> get todayTasks {
    return _tasks.where((t) {
      if (t.dueDate != null && DateFormatter.isToday(t.dueDate)) return true;
      if (t.isCompleted && t.completedAt != null && DateFormatter.isToday(t.completedAt)) return true;
      return false;
    }).toList();
  }

  List<Task> get upcomingDeadlines {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks
        .where((t) => !t.isCompleted && t.dueDate != null && !t.dueDate!.isBefore(today))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Task> get overdueTasks {
    return _tasks.where((t) => !t.isCompleted && DateFormatter.isOverdue(t.dueDate)).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Task> get recentlyUpdatedTasks {
    final list = List<Task>.from(_tasks);
    list.sort((a, b) {
      final aDate = a.completedAt ?? a.createdAt;
      final bDate = b.completedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return list.take(8).toList();
  }

  StreakResult get streakResult => StreakCalculator.calculate(_tasks);

  int get todayCompletedCount {
    return _tasks.where((t) => t.isCompleted && DateFormatter.isToday(t.completedAt)).length;
  }

  bool get isDailyGoalMet => todayCompletedCount >= _dailyGoal;

  // Phase Progress Helper
  double getPhaseProgress(String phaseId) {
    final phaseTasks = _tasks.where((t) => t.phaseId == phaseId).toList();
    if (phaseTasks.isEmpty) return 0.0;
    final done = phaseTasks.where((t) => t.isCompleted).length;
    return (done / phaseTasks.length).clamp(0.0, 1.0);
  }

  int getPhaseTasksCount(String phaseId) => _tasks.where((t) => t.phaseId == phaseId).length;
  int getPhaseCompletedCount(String phaseId) =>
      _tasks.where((t) => t.phaseId == phaseId && t.isCompleted).length;
  int getPhaseRemainingCount(String phaseId) =>
      _tasks.where((t) => t.phaseId == phaseId && !t.isCompleted).length;

  Future<void> _loadAllData() async {
    _isLoading = true;
    notifyListeners();

    if (!_db.isInitialized) {
      await _db.init();
    }

    _phases = _db.getAllPhases();
    _tasks = _db.getAllTasks();
    _projects = _db.getAllProjects();
    _notes = _db.getAllNotes();

    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt(_prefDailyGoal) ?? 3;

    _isLoading = false;
    notifyListeners();
  }

  // --- Task Actions ---
  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final current = _tasks[index];
    final willBeCompleted = !current.isCompleted;

    final updated = current.copyWith(
      status: willBeCompleted ? TaskStatus.completed : TaskStatus.pending,
      completedAt: willBeCompleted ? DateTime.now() : null,
      clearCompletedAt: !willBeCompleted,
    );

    _tasks[index] = updated;
    notifyListeners();
    await _db.saveTask(updated);
  }

  Future<void> saveTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    notifyListeners();
    await _db.saveTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _db.deleteTask(taskId);
  }

  Future<void> bulkCompleteTasks(List<String> taskIds, bool complete) async {
    final now = DateTime.now();
    for (var id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index >= 0) {
        _tasks[index] = _tasks[index].copyWith(
          status: complete ? TaskStatus.completed : TaskStatus.pending,
          completedAt: complete ? now : null,
          clearCompletedAt: !complete,
        );
        await _db.saveTask(_tasks[index]);
      }
    }
    notifyListeners();
  }

  // --- Phase Actions ---
  Future<void> savePhase(Phase phase) async {
    final index = _phases.indexWhere((p) => p.id == phase.id);
    if (index >= 0) {
      _phases[index] = phase;
    } else {
      _phases.add(phase);
    }
    _phases.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
    await _db.savePhase(phase);
  }

  Future<void> deletePhase(String phaseId) async {
    _phases.removeWhere((p) => p.id == phaseId);
    _tasks.removeWhere((t) => t.phaseId == phaseId);
    _projects.removeWhere((p) => p.phaseId == phaseId);
    notifyListeners();
    await _db.deletePhase(phaseId);
  }

  Future<void> reorderPhases(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _phases.removeAt(oldIndex);
    _phases.insert(newIndex, item);

    for (int i = 0; i < _phases.length; i++) {
      _phases[i] = _phases[i].copyWith(order: i + 1);
    }
    notifyListeners();
    await _db.saveAllPhases(_phases);
  }

  // --- Project Actions ---
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    notifyListeners();
    await _db.saveProject(project);
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    notifyListeners();
    await _db.deleteProject(projectId);
  }

  Future<void> toggleProjectChecklistItem(String projectId, String itemId) async {
    final pIndex = _projects.indexWhere((p) => p.id == projectId);
    if (pIndex == -1) return;

    final project = _projects[pIndex];
    final updatedChecklist = project.checklist.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    // Check if all items completed
    final allDone = updatedChecklist.isNotEmpty && updatedChecklist.every((i) => i.isCompleted);
    final updatedProject = project.copyWith(
      checklist: updatedChecklist,
      status: allDone ? ProjectStatus.completed : project.status,
      completedAt: allDone ? DateTime.now() : project.completedAt,
    );

    _projects[pIndex] = updatedProject;
    notifyListeners();
    await _db.saveProject(updatedProject);
  }

  // --- Note Actions ---
  Future<void> saveNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _db.saveNote(note);
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _db.deleteNote(noteId);
  }

  List<Note> getNotesForEntity(String entityId) {
    return _notes.where((n) => n.relatedEntityId == entityId).toList();
  }

  // --- Import Roadmap Action ---
  Future<void> importParsedRoadmap(ParsedImportResult result) async {
    final now = DateTime.now();
    int currentOrder = _phases.length;

    final newPhases = <Phase>[];
    final newTasks = <Task>[];
    final newProjects = <Project>[];

    for (var pPhase in result.phases) {
      currentOrder++;
      final phase = Phase(
        id: pPhase.id,
        title: pPhase.title,
        description: pPhase.description,
        weekDuration: pPhase.weekDuration,
        order: currentOrder,
        createdAt: now,
      );
      newPhases.add(phase);

      for (var pTask in pPhase.tasks) {
        if (!pTask.isSelected) continue;
        final task = Task(
          id: pTask.id,
          phaseId: phase.id,
          title: pTask.title,
          description: pTask.description,
          priority: pTask.priority,
          status: TaskStatus.pending,
          createdAt: now,
        );
        newTasks.add(task);
      }

      for (var pProj in pPhase.projects) {
        if (!pProj.isSelected) continue;
        final checklist = pProj.checklist
            .map((item) => ProjectChecklistItem(
                  id: _uuid.v4(),
                  projectId: pProj.id,
                  title: item,
                  isCompleted: false,
                ))
            .toList();

        final project = Project(
          id: pProj.id,
          title: pProj.title,
          description: pProj.description,
          phaseId: phase.id,
          status: ProjectStatus.pending,
          checklist: checklist,
          createdAt: now,
        );
        newProjects.add(project);
      }
    }

    _phases.addAll(newPhases);
    _tasks.addAll(newTasks);
    _projects.addAll(newProjects);

    notifyListeners();

    await _db.saveAllPhases(newPhases);
    await _db.saveAllTasks(newTasks);
    await _db.saveAllProjects(newProjects);
  }

  // --- Settings Actions ---
  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefDailyGoal, goal);
  }

  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere((t) => t.isCompleted);
    notifyListeners();
    await _db.clearCompletedTasks();
  }

  Future<void> resetAllData() async {
    _phases.clear();
    _tasks.clear();
    _projects.clear();
    _notes.clear();
    _dailyGoal = 3;
    notifyListeners();
    await _db.resetAllData();
  }

  Future<void> reloadData() async {
    await _loadAllData();
  }
}
