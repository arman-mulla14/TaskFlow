class Phase {
  final String id;
  final String title;
  final String description;
  final String weekDuration;
  final int order;
  final DateTime createdAt;

  const Phase({
    required this.id,
    required this.title,
    this.description = '',
    this.weekDuration = '',
    this.order = 0,
    required this.createdAt,
  });

  Phase copyWith({
    String? id,
    String? title,
    String? description,
    String? weekDuration,
    int? order,
    DateTime? createdAt,
  }) {
    return Phase(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekDuration: weekDuration ?? this.weekDuration,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weekDuration': weekDuration,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Phase',
      description: json['description'] as String? ?? '',
      weekDuration: json['weekDuration'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Phase && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
