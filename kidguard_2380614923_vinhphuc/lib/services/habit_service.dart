import 'dart:convert';
import '../models/habit_quest_model.dart';
import 'api_client.dart';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final ApiClient _client = ApiClient();

  // GET: Lấy danh sách nhiệm vụ rèn luyện
  Future<List<HabitQuestModel>> getQuests(int deviceId) async {
    try {
      final response = await _client.get('HabitQuests/device/$deviceId');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => HabitQuestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // POST: Phụ huynh giao nhiệm vụ mới
  Future<bool> createQuest(HabitQuestModel quest) async {
    try {
      final response = await _client.post('HabitQuests', quest.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // PUT: Trẻ hoàn thành nhiệm vụ
  Future<bool> completeQuest(int id) async {
    try {
      final response = await _client.put('HabitQuests/$id/complete', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // PUT: Phụ huynh duyệt thưởng thêm phút sử dụng
  Future<Map<String, dynamic>> approveQuest(int id) async {
    try {
      final response = await _client.put('HabitQuests/$id/approve', {});
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Đã duyệt thưởng!',
        'newLimit': data['newScreenLimit'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // DELETE: Xóa nhiệm vụ
  Future<bool> deleteQuest(int id) async {
    try {
      final response = await _client.delete('HabitQuests/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
