import 'dart:convert';
import '../models/app_restriction_model.dart';
import 'api_client.dart';

class AppRuleService {
  static final AppRuleService _instance = AppRuleService._internal();
  factory AppRuleService() => _instance;
  AppRuleService._internal();

  final ApiClient _client = ApiClient();

  // GET: Lấy danh sách app theo thiết bị
  Future<List<AppRestrictionModel>> getApps(int deviceId) async {
    try {
      final response = await _client.get('AppRestrictions/device/$deviceId');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => AppRestrictionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // POST: Thêm quy tắc giới hạn app
  Future<AppRestrictionModel?> createApp(AppRestrictionModel app) async {
    try {
      final response = await _client.post('AppRestrictions', app.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return AppRestrictionModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // PUT: Sửa quy tắc app
  Future<bool> updateApp(AppRestrictionModel app) async {
    try {
      final response = await _client.put('AppRestrictions/${app.id}', app.toJson());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // PUT: Bật / Tắt khóa app ngay lập tức
  Future<bool> toggleBlock(int id) async {
    try {
      final response = await _client.put('AppRestrictions/$id/toggle-block', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // DELETE: Xóa quy tắc app
  Future<bool> deleteApp(int id) async {
    try {
      final response = await _client.delete('AppRestrictions/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
