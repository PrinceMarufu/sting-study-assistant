import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../repositories/notes_repository.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/planner_repository.dart';
import '../repositories/ai_chat_repository.dart';
import '../models/note_model.dart';
import '../models/quiz_model.dart';
import '../models/study_task_model.dart';
import '../models/chat_message_model.dart';

// --- Repositories ---

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(supabaseClientProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.watch(supabaseClientProvider));
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(supabaseClientProvider));
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository(ref.watch(supabaseClientProvider));
});

// --- Streams (Real-time synchronization) ---

final notesStreamProvider = StreamProvider<List<NoteModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(notesRepositoryProvider).getNotesStream(user.id);
});

final quizHistoryStreamProvider = StreamProvider<List<QuizModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(quizRepositoryProvider).getQuizHistoryStream(user.id);
});

final tasksStreamProvider = StreamProvider<List<StudyTaskModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(plannerRepositoryProvider).getTasksStream(user.id);
});

final aiChatStreamProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(aiChatRepositoryProvider).getChatHistoryStream(user.id);
});
