import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';

class NotesRepository {
  final SupabaseClient _client;

  NotesRepository(this._client);

  Stream<List<NoteModel>> getNotesStream(String userId) {
    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at')
        .map((maps) => maps.map((map) => NoteModel.fromJson(map)).toList());
  }

  Future<List<NoteModel>> getNotes(String userId) async {
    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List).map((map) => NoteModel.fromJson(map)).toList();
  }

  Future<void> createNote(NoteModel note) async {
    await _client.from('notes').insert(note.toJson());
  }

  Future<void> updateNote(NoteModel note) async {
    await _client
        .from('notes')
        .update(note.toJson())
        .eq('id', note.id);
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }

  Future<String?> uploadPDF({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}-$fileName';
      
      await _client.storage.from('pdf_notes').uploadBinary(
        uniqueFileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'application/pdf'),
      );
      
      return _client.storage.from('pdf_notes').getPublicUrl(uniqueFileName);
    } catch (e) {
      rethrow;
    }
  }
}
