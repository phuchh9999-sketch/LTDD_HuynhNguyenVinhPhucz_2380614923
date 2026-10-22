import 'dart:convert';
import '../models/safe_zone_model.dart';
import 'api_client.dart';

class SafeZoneService {
  static final SafeZoneService _instance = SafeZoneService._internal();
  factory SafeZoneService() => _instance;
  SafeZoneService._internal();

  final ApiClient _client = ApiClient();

  // GET: Lấy danh sách vùng an toàn của thiết bị
  Future<List<SafeZoneModel>> getSafeZones(int deviceId) async {
    try {
      final response = await _client.get('SafeZones/device/$deviceId');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => SafeZoneModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // POST: Tạo vùng an toàn mới
  Future<SafeZoneModel?> createSafeZone(SafeZoneModel zone) async {
    try {
      final response = await _client.post('SafeZones', zone.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SafeZoneModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // PUT: Sửa vùng an toàn
  Future<bool> updateSafeZone(SafeZoneModel zone) async {
    try {
      final response = await _client.put('SafeZones/${zone.id}', zone.toJson());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // DELETE: Xóa vùng an toàn
  Future<bool> deleteSafeZone(int id) async {
    try {
      final response = await _client.delete('SafeZones/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
