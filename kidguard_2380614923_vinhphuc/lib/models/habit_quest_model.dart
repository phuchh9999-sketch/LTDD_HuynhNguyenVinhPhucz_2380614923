class HabitQuestModel {
  final int id;
  final int childDeviceId;
  String title;
  String description;
  int rewardMinutes;
  bool isCompleted;
  bool isApproved;
  DateTime? createdAt;

  HabitQuestModel({
    required this.id,
    required this.childDeviceId,
    required this.title,
    this.description = '',
    this.rewardMinutes = 30,
    this.isCompleted = false,
    this.isApproved = false,
    this.createdAt,
  });

  factory HabitQuestModel.fromJson(Map<String, dynamic> json) {
    return HabitQuestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      childDeviceId: json['childDeviceId'] is int ? json['childDeviceId'] : int.tryParse(json['childDeviceId'].toString()) ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rewardMinutes: json['rewardMinutes'] ?? 30,
      isCompleted: json['isCompleted'] ?? false,
      isApproved: json['isApproved'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childDeviceId': childDeviceId,
      'title': title,
      'description': description,
      'rewardMinutes': rewardMinutes,
      'isCompleted': isCompleted,
      'isApproved': isApproved,
    };
  }
}
