class StudyTaskModel {
  final String id;
  final String userId;
  final String taskTitle;
  final String? taskDescription;
  final DateTime? dueDate;
  final bool completed;
  final DateTime createdAt;

  StudyTaskModel({
    required this.id,
    required this.userId,
    required this.taskTitle,
    this.taskDescription,
    this.dueDate,
    required this.completed,
    required this.createdAt,
  });

  factory StudyTaskModel.fromJson(Map<String, dynamic> json) {
    return StudyTaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskTitle: json['task_title'] as String? ?? '',
      taskDescription: json['task_description'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'task_title': taskTitle,
      'task_description': taskDescription,
      'due_date': dueDate?.toIso8601String(),
      'completed': completed,
    };
  }

  StudyTaskModel copyWith({
    String? id,
    String? userId,
    String? taskTitle,
    String? taskDescription,
    DateTime? dueDate,
    bool? completed,
    DateTime? createdAt,
  }) {
    return StudyTaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
