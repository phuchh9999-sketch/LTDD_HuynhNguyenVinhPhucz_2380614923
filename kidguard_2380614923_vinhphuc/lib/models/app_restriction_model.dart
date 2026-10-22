class AppRestrictionModel {
  final int id;
  final int childDeviceId;
  String appName;
  String packageName;
  String category;
  String? appIcon;
  int dailyLimitMinutes;
  bool isBlocked;

  AppRestrictionModel({
    required this.id,
    required this.childDeviceId,
    required this.appName,
    this.packageName = '',
    this.category = 'Giải trí',
    this.appIcon,
    this.dailyLimitMinutes = 30,
    this.isBlocked = false,
  });

  factory AppRestrictionModel.fromJson(Map<String, dynamic> json) {
    return AppRestrictionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      childDeviceId: json['childDeviceId'] is int ? json['childDeviceId'] : int.tryParse(json['childDeviceId'].toString()) ?? 0,
      appName: json['appName'] ?? '',
      packageName: json['packageName'] ?? '',
      category: json['category'] ?? 'Giải trí',
      appIcon: json['appIcon'],
      dailyLimitMinutes: json['dailyLimitMinutes'] ?? 30,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childDeviceId': childDeviceId,
      'appName': appName,
      'packageName': packageName,
      'category': category,
      'appIcon': appIcon,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isBlocked': isBlocked,
    };
  }
}
