import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/api_config.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không tìm thấy file .env, sử dụng cấu hình mặc định: $e");
  }
  await ApiConfig.init();
  runApp(const KidGuardApp());
}

class KidGuardApp extends StatelessWidget {
  const KidGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ApiConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Modern Indigo
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
