class ChatMessageModel {
  final String id;
  final String userId;
  final String message;
  final String response;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.response,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String? ?? '',
      response: json['response'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
      'response': response,
    };
  }
}
