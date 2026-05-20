import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_task_model.dart';

class PlannerRepository {
  final SupabaseClient _client;

  PlannerRepository(this._client);

  Stream<List<StudyTaskModel>> getTasksStream(String userId) {
    return _client
        .from('study_tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('due_date')
        .map((maps) => maps.map((map) => StudyTaskModel.fromJson(map)).toList());
  }

  Future<List<StudyTaskModel>> getTasks(String userId) async {
    final response = await _client
        .from('study_tasks')
        .select()
        .eq('user_id', userId)
        .order('due_date', ascending: true);
    return (response as List).map((map) => StudyTaskModel.fromJson(map)).toList();
  }

  Future<void> createTask(StudyTaskModel task) async {
    await _client.from('study_tasks').insert(task.toJson());
  }

  Future<void> updateTask(StudyTaskModel task) async {
    await _client
        .from('study_tasks')
        .update(task.toJson())
        .eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('study_tasks').delete().eq('id', taskId);
  }
}
