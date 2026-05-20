import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';

class AiChatRepository {
  final SupabaseClient _client;

  AiChatRepository(this._client);

  Stream<List<ChatMessageModel>> getChatHistoryStream(String userId) {
    return _client
        .from('ai_chats')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((maps) => maps.map((map) => ChatMessageModel.fromJson(map)).toList());
  }

  Future<List<ChatMessageModel>> getChatHistory(String userId, {int limit = 50, int offset = 0}) async {
    final response = await _client
        .from('ai_chats')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((map) => ChatMessageModel.fromJson(map)).toList();
  }

  Future<void> saveChatMessage(ChatMessageModel message) async {
    await _client.from('ai_chats').insert(message.toJson());
  }
}
