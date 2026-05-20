import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class SupabaseService {
  static Future<void> initialize() async {
    final url = Constants.supabaseUrl;
    final anonKey = Constants.supabaseAnonKey;
    
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('Supabase URL and Anon Key must be provided in the .env file.');
    }
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
