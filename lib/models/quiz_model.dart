class QuizModel {
  final String id;
  final String userId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.userId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.createdAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quizTitle: json['quiz_title'] as String? ?? 'Quiz',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'quiz_title': quizTitle,
      'score': score,
      'total_questions': totalQuestions,
    };
  }
}
