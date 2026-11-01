class ProjectChecklistItem {
  final String id;
  final String projectId;
  final String title;
  final bool isCompleted;

  const ProjectChecklistItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
  });

  ProjectChecklistItem copyWith({
    String? id,
    String? projectId,
    String? title,
    bool? isCompleted,
  }) {
    return ProjectChecklistItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory ProjectChecklistItem.fromJson(Map<String, dynamic> json) {
    return ProjectChecklistItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectChecklistItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

