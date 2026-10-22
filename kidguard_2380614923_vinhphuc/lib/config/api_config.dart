import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String? _customBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('custom_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _customBaseUrl = savedUrl.endsWith('/') ? savedUrl : '$savedUrl/';
      }
    } catch (e) {
      debugPrint('Lỗi tải URL tùy chỉnh: $e');
    }
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final formatted = url.endsWith('/') ? url : '$url/';
    _customBaseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', formatted);
    } catch (e) {
      debugPrint('Lỗi lưu URL tùy chỉnh: $e');
    }
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      // Nếu chạy trên Android Emulator và URL là localhost, tự động map sang 10.0.2.2
      if (!kIsWeb && Platform.isAndroid && envUrl.contains('localhost')) {
        return envUrl.replaceAll('localhost', '10.0.2.2');
      }
      return envUrl.endsWith('/') ? envUrl : '$envUrl/';
    }

    if (kIsWeb || (!kIsWeb && Platform.isWindows)) {
      return 'http://localhost:5271/api/';
    } else if (!kIsWeb && Platform.isAndroid) {
      return 'http://127.0.0.1:5271/api/';
    }
    return 'http://localhost:5271/api/';
  }

  static const String appTitle = 'KidGuard 2380614923';
  static const String studentName = 'Huỳnh Nguyễn Vĩnh Phúc';
  static const String studentId = '2380614923';
  static const String groupName = 'goddy';
}
