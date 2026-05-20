import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String academicLevel,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'academic_level': academicLevel,
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<String?> uploadProfileImage(String path, Uint8List bytes) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage.from('profile_images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final imageUrl = _client.storage.from('profile_images').getPublicUrl(fileName);
      
      // Update public.users profile_image field
      await _client.from('users').update({
        'profile_image': imageUrl,
      }).eq('id', userId);

      return imageUrl;
    } catch (e) {
      rethrow;
    }
  }
}
