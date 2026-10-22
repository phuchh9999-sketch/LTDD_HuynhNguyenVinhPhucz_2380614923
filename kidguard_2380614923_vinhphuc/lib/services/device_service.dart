import 'dart:convert';
import '../models/child_device_model.dart';
import 'api_client.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final ApiClient _client = ApiClient();

  // GET: Lấy danh sách thiết bị
  Future<List<ChildDeviceModel>> getDevices({String? parentId}) async {
    try {
      final endpoint = parentId != null ? 'ChildDevices?parentId=$parentId' : 'ChildDevices';
      final response = await _client.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => ChildDeviceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET: Chi tiết 1 thiết bị
  Future<ChildDeviceModel?> getDevice(int id) async {
    try {
      final response = await _client.get('ChildDevices/$id');
      if (response.statusCode == 200) {
        return ChildDeviceModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // POST: Tạo thiết bị mới (Kèm mã QR code ghép đôi)
  Future<ChildDeviceModel?> createDevice(ChildDeviceModel device) async {
    try {
      final response = await _client.post('ChildDevices', device.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ChildDeviceModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // PUT: Sửa thông tin thiết bị
  Future<bool> updateDevice(ChildDeviceModel device) async {
    try {
      final response = await _client.put('ChildDevices/${device.id}', device.toJson());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // PUT: Khóa / Mở khóa thiết bị từ xa (Remote Lock)
  Future<bool> toggleLock(int deviceId, bool isLocked) async {
    try {
      final response = await _client.put('ChildDevices/$deviceId/lock', isLocked);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // POST: Cập nhật vị trí GPS và cảm biến tiếng ồn thời gian thực
  Future<bool> updateLocation({
    required int childDeviceId,
    required double latitude,
    required double longitude,
    String? address,
    double? noiseDecibel,
    int? batteryLevel,
  }) async {
    try {
      final response = await _client.post('ChildDevices/location', {
        'childDeviceId': childDeviceId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'noiseDecibel': noiseDecibel,
        'batteryLevel': batteryLevel,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // POST: Ghép đôi thiết bị qua mã QR
  Future<Map<String, dynamic>> pairDevice({
    required String deviceCode,
    String? parentId,
  }) async {
    try {
      final response = await _client.post('ChildDevices/pair', {
        'deviceCode': deviceCode,
        'parentId': parentId,
      });
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['status'] == true,
        'message': data['message'] ?? 'Ghép đôi thành công',
        'device': data['device'] != null ? ChildDeviceModel.fromJson(data['device']) : null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // DELETE: Xóa thiết bị
  Future<bool> deleteDevice(int id) async {
    try {
      final response = await _client.delete('ChildDevices/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
