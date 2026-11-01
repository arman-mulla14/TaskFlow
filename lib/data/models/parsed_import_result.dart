import 'task_model.dart';

class ParsedTask {
  String id;
  String title;
  String description;
  TaskPriority priority;
  bool isSelected;

  ParsedTask({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.isSelected = true,
  });

  ParsedTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isSelected,
  }) {
    return ParsedTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ParsedProject {
  String id;
  String title;
  String description;
  List<String> checklist;
  bool isSelected;

  ParsedProject({
    required this.id,
    required this.title,
    this.description = '',
    this.checklist = const [],
    this.isSelected = true,
  });
}

class ParsedPhase {
  String id;
  String title;
  String description;
  String weekDuration;
  int order;
  List<ParsedTask> tasks;
  List<ParsedProject> projects;

  ParsedPhase({
    required this.id,
    required this.title,
    this.description = '',
    this.weekDuration = '',
    required this.order,
    List<ParsedTask>? tasks,
    List<ParsedProject>? projects,
  })  : tasks = tasks ?? [],
        projects = projects ?? [];
}

class ParsedImportResult {
  final List<ParsedPhase> phases;
  final List<String> unparsedLines;
  final int rawLineCount;

  const ParsedImportResult({
    required this.phases,
    required this.unparsedLines,
    required this.rawLineCount,
  });

  int get totalTasks => phases.fold(0, (acc, p) => acc + p.tasks.length);
  int get selectedTasks =>
      phases.fold(0, (acc, p) => acc + p.tasks.where((t) => t.isSelected).length);
  int get totalProjects => phases.fold(0, (acc, p) => acc + p.projects.length);
}

