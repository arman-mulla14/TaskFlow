class Note {
  final String id;
  final String relatedEntityId;
  final String entityType;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.relatedEntityId,
    this.entityType = 'general',
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? relatedEntityId,
    String? entityType,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      entityType: entityType ?? this.entityType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relatedEntityId': relatedEntityId,
      'entityType': entityType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      relatedEntityId: json['relatedEntityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'general',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

