import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'themes/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Load environment variables from .env
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint("Initialization failed: $e");
  }
  runApp(const ProviderScope(child: SSAApp()));
}

class SSAApp extends StatelessWidget {
  const SSAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sting Study Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
