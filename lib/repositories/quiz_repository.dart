import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final SupabaseClient _client;

  QuizRepository(this._client);

  Stream<List<QuizModel>> getQuizHistoryStream(String userId) {
    return _client
        .from('quizzes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((maps) => maps.map((map) => QuizModel.fromJson(map)).toList());
  }

  Future<List<QuizModel>> getQuizHistory(String userId) async {
    final response = await _client
        .from('quizzes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((map) => QuizModel.fromJson(map)).toList();
  }

  Future<void> saveQuizResult(QuizModel quiz) async {
    await _client.from('quizzes').insert(quiz.toJson());
  }
}
