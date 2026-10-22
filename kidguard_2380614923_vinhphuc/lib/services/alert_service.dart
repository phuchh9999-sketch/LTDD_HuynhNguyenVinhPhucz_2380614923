import 'dart:convert';
import '../models/security_alert_model.dart';
import 'api_client.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final ApiClient _client = ApiClient();

  // GET: Lấy danh sách cảnh báo
  Future<List<SecurityAlertModel>> getAlerts({int? deviceId, bool? isResolved}) async {
    try {
      String endpoint = 'SecurityAlerts';
      final params = <String>[];
      if (deviceId != null) params.add('deviceId=$deviceId');
      if (isResolved != null) params.add('isResolved=$isResolved');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';

      final response = await _client.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => SecurityAlertModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // POST: Kích hoạt cảnh báo khẩn cấp từ thiết bị con (SOS, Âm thanh bất thường, Rung lắc gia tốc)
  Future<Map<String, dynamic>> triggerAlert({
    required int childDeviceId,
    String alertType = 'SOS_MANUAL',
    String title = 'Cảnh báo khẩn cấp',
    String description = '',
    double latitude = 10.776889,
    double longitude = 106.700806,
    double noiseDecibel = 0.0,
    String severity = 'Critical',
  }) async {
    try {
      final response = await _client.post('SecurityAlerts/trigger', {
        'childDeviceId': childDeviceId,
        'alertType': alertType,
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'noiseDecibel': noiseDecibel,
        'severity': severity,
      });

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['status'] == true,
        'message': data['message'] ?? 'Đã phát cảnh báo',
        'alert': data['alert'] != null ? SecurityAlertModel.fromJson(data['alert']) : null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối cảnh báo: $e'};
    }
  }

  // PUT: Đánh dấu đã xử lý
  Future<bool> resolveAlert(int id) async {
    try {
      final response = await _client.put('SecurityAlerts/$id/resolve', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // DELETE: Xóa cảnh báo
  Future<bool> deleteAlert(int id) async {
    try {
      final response = await _client.delete('SecurityAlerts/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
