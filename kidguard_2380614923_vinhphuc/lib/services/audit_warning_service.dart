import 'dart:convert';
import 'api_client.dart';

class AuditWarningService {
  static final AuditWarningService _instance = AuditWarningService._internal();
  factory AuditWarningService() => _instance;
  AuditWarningService._internal();

  final ApiClient _client = ApiClient();

  // 1. Lấy lịch sử thêm / xóa / hành động của phụ huynh
  Future<List<Map<String, dynamic>>> getParentAuditLogs([String? parentId]) async {
    try {
      final endpoint = parentId != null && parentId.isNotEmpty
          ? 'AuditAndWarning/audit?parentId=$parentId'
          : 'AuditAndWarning/audit';
      final res = await _client.get(endpoint);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Admin lấy danh sách các báo cáo từ nhân viên
  Future<List<Map<String, dynamic>>> getStaffReports() async {
    try {
      final res = await _client.get('AuditAndWarning/staff-reports');
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 3. Nhân viên gửi báo cáo sự cố / hành động bất thường lên Admin
  Future<bool> createStaffReport({
    required String title,
    required String reason,
    String severity = 'Warning',
    String? parentId,
    String? parentName,
    int? childDeviceId,
    String? childName,
  }) async {
    try {
      final res = await _client.post('AuditAndWarning/staff-reports', {
        'staffId': 'staff01',
        'staffName': 'Nguyễn Văn Tuấn (Kỹ Thuật Viên)',
        'parentId': parentId,
        'parentName': parentName,
        'childDeviceId': childDeviceId,
        'childName': childName,
        'title': title,
        'reason': reason,
        'severity': severity,
      });
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // 4. Admin xử lý báo cáo từ nhân viên
  Future<bool> updateStaffReportStatus(int id, String status, [String? adminNotes]) async {
    try {
      final res = await _client.put('AuditAndWarning/staff-reports/$id/status', {
        'status': status,
        'adminNotes': adminNotes,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Lấy danh sách cảnh báo từ Admin gửi cho phụ huynh
  Future<List<Map<String, dynamic>>> getAdminWarnings([String? parentId]) async {
    try {
      final endpoint = parentId != null && parentId.isNotEmpty
          ? 'AuditAndWarning/warnings?parentId=$parentId'
          : 'AuditAndWarning/warnings';
      final res = await _client.get(endpoint);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 6. Admin gửi cảnh báo cho phụ huynh
  Future<bool> sendAdminWarning({
    required String parentId,
    String? parentName,
    required String title,
    required String message,
    String severity = 'Warning',
  }) async {
    try {
      final res = await _client.post('AuditAndWarning/warnings', {
        'parentId': parentId,
        'parentName': parentName,
        'adminName': 'Quản Trị Viên Hệ Thống',
        'title': title,
        'message': message,
        'severity': severity,
      });
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // 7. Phụ huynh đánh dấu đã đọc cảnh báo
  Future<bool> markWarningRead(int id) async {
    try {
      final res = await _client.put('AuditAndWarning/warnings/$id/read', {});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 8. Nhân viên lấy toàn bộ nhiệm vụ của tất cả phụ huynh giao cho bé
  Future<List<Map<String, dynamic>>> getAllHabitQuests() async {
    try {
      final res = await _client.get('HabitQuests/all');
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 9. Nhân viên kiểm duyệt nhiệm vụ: "Approved" (Hợp chuẩn) hoặc "Flagged" (Không đúng mực)
  Future<bool> moderateHabitQuest(int questId, String moderationStatus, [String? staffNotes]) async {
    try {
      final res = await _client.put('HabitQuests/$questId/moderate', {
        'moderationStatus': moderationStatus,
        'staffNotes': staffNotes,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
