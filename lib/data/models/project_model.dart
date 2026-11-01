import 'project_checklist_item_model.dart';

enum ProjectStatus {
  pending,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case ProjectStatus.pending:
        return 'Pending';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }

  static ProjectStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'completed':
        return ProjectStatus.completed;
      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return ProjectStatus.inProgress;
      case 'pending':
      default:
        return ProjectStatus.pending;
    }
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String phaseId;
  final ProjectStatus status;
  final List<ProjectChecklistItem> checklist;
  final String notes;
  final DateTime? startDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Project({
    required this.id,
    required this.title,
    this.description = '',
    this.phaseId = '',
    this.status = ProjectStatus.pending,
    this.checklist = const [],
    this.notes = '',
    this.startDate,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == ProjectStatus.completed;

  int get completedChecklistCount => checklist.where((i) => i.isCompleted).length;
  int get totalChecklistCount => checklist.length;
  double get checklistProgress =>
      checklist.isEmpty ? 0.0 : completedChecklistCount / checklist.length;

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? phaseId,
    ProjectStatus? status,
    List<ProjectChecklistItem>? checklist,
    String? notes,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      phaseId: phaseId ?? this.phaseId,
      status: status ?? this.status,
      checklist: checklist ?? this.checklist,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'phaseId': phaseId,
      'status': status.name,
      'checklist': checklist.map((i) => i.toJson()).toList(),
      'notes': notes,
      'startDate': startDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Project',
      description: json['description'] as String? ?? '',
      phaseId: json['phaseId'] as String? ?? '',
      status: ProjectStatus.fromString(json['status'] as String?),
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((i) => ProjectChecklistItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

