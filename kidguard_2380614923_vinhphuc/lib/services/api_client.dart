import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static String? memoryToken;
  static String? _workingBaseUrl;

  List<String> get _candidateHosts {
    if (_workingBaseUrl != null) {
      return [_workingBaseUrl!];
    }
    final primary = ApiConfig.baseUrl;
    final candidates = <String>[primary];

    if (!kIsWeb && Platform.isAndroid) {
      // Các địa chỉ phổ biến của máy tính Host khi chạy qua BlueStacks / Máy ảo / Wi-Fi LAN
      final defaults = [
        'http://10.0.2.2:5271/api/',
        'http://192.168.1.6:5271/api/',
        'http://127.0.0.1:5271/api/',
      ];
      for (final host in defaults) {
        if (!candidates.contains(host)) {
          candidates.add(host);
        }
      }
    }
    return candidates;
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = memoryToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_token') ?? memoryToken;
    } catch (_) {
      token = memoryToken;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _executeWithFallback(
    String endpoint,
    Future<http.Response> Function(String fullUrl, Map<String, String> headers) requestFn, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final headers = await _getHeaders();
    final hosts = _candidateHosts;
    dynamic lastError;

    for (int i = 0; i < hosts.length; i++) {
      final host = hosts[i];
      final fullUrl = '$host$endpoint';
      try {
        final response = await requestFn(fullUrl, headers).timeout(timeout);
        _workingBaseUrl = host;
        return response;
      } catch (e) {
        lastError = e;
        if (i < hosts.length - 1) {
          debugPrint('Host $host không phản hồi, thử tiếp host ${hosts[i + 1]}...');
          continue;
        }
      }
    }

    throw lastError ?? Exception('Không thể kết nối đến máy chủ WebAPI');
  }

  Future<http.Response> get(String endpoint, {Duration timeout = const Duration(seconds: 15)}) async {
    return await _executeWithFallback(
      endpoint,
      (url, headers) => http.get(Uri.parse(url), headers: headers),
      timeout: timeout,
    );
  }

  Future<http.Response> post(String endpoint, dynamic body, {Duration timeout = const Duration(seconds: 15)}) async {
    final bodyJson = jsonEncode(body);
    return await _executeWithFallback(
      endpoint,
      (url, headers) => http.post(Uri.parse(url), headers: headers, body: bodyJson),
      timeout: timeout,
    );
  }

  Future<http.Response> put(String endpoint, dynamic body, {Duration timeout = const Duration(seconds: 15)}) async {
    final bodyJson = jsonEncode(body);
    return await _executeWithFallback(
      endpoint,
      (url, headers) => http.put(Uri.parse(url), headers: headers, body: bodyJson),
      timeout: timeout,
    );
  }

  Future<http.Response> delete(String endpoint, {Duration timeout = const Duration(seconds: 15)}) async {
    return await _executeWithFallback(
      endpoint,
      (url, headers) => http.delete(Uri.parse(url), headers: headers),
      timeout: timeout,
    );
  }
}
