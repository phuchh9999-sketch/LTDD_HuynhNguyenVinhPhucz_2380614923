import 'app_restriction_model.dart';
import 'safe_zone_model.dart';
import 'security_alert_model.dart';

class ChildDeviceModel {
  final int id;
  String deviceName;
  String modelName;
  String osVersion;
  String deviceCode;
  String? parentId;
  String? childUserId;
  String childName;
  int dailyScreenTimeLimitMinutes;
  int usedScreenTimeMinutes;
  bool isLocked;
  int batteryLevel;
  double currentLatitude;
  double currentLongitude;
  String? currentAddress;
  DateTime? lastLocationTime;
  double currentNoiseLevel;
  bool isOnline;
  List<AppRestrictionModel> appRestrictions;
  List<SafeZoneModel> safeZones;
  List<SecurityAlertModel> securityAlerts;

  ChildDeviceModel({
    required this.id,
    required this.deviceName,
    this.modelName = 'Android Smartphone',
    this.osVersion = 'Android 14',
    required this.deviceCode,
    this.parentId,
    this.childUserId,
    required this.childName,
    this.dailyScreenTimeLimitMinutes = 120,
    this.usedScreenTimeMinutes = 30,
    this.isLocked = false,
    this.batteryLevel = 85,
    this.currentLatitude = 10.776889,
    this.currentLongitude = 106.700806,
    this.currentAddress,
    this.lastLocationTime,
    this.currentNoiseLevel = 45.0,
    this.isOnline = true,
    this.appRestrictions = const [],
    this.safeZones = const [],
    this.securityAlerts = const [],
  });

  factory ChildDeviceModel.fromJson(Map<String, dynamic> json) {
    return ChildDeviceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      deviceName: json['deviceName'] ?? 'Thiết bị trẻ em',
      modelName: json['modelName'] ?? 'Smartphone',
      osVersion: json['osVersion'] ?? 'Android',
      deviceCode: json['deviceCode'] ?? '',
      parentId: json['parentId'],
      childUserId: json['childUserId'],
      childName: json['childName'] ?? 'Bé',
      dailyScreenTimeLimitMinutes: json['dailyScreenTimeLimitMinutes'] ?? 120,
      usedScreenTimeMinutes: json['usedScreenTimeMinutes'] ?? 0,
      isLocked: json['isLocked'] ?? false,
      batteryLevel: json['batteryLevel'] ?? 80,
      currentLatitude: (json['currentLatitude'] is num) ? (json['currentLatitude'] as num).toDouble() : 10.776889,
      currentLongitude: (json['currentLongitude'] is num) ? (json['currentLongitude'] as num).toDouble() : 106.700806,
      currentAddress: json['currentAddress'] ?? 'TP. Hồ Chí Minh',
      lastLocationTime: json['lastLocationTime'] != null ? DateTime.tryParse(json['lastLocationTime']) : null,
      currentNoiseLevel: (json['currentNoiseLevel'] is num) ? (json['currentNoiseLevel'] as num).toDouble() : 45.0,
      isOnline: json['isOnline'] ?? true,
      appRestrictions: (json['appRestrictions'] as List<dynamic>?)
              ?.map((e) => AppRestrictionModel.fromJson(e))
              .toList() ??
          [],
      safeZones: (json['safeZones'] as List<dynamic>?)
              ?.map((e) => SafeZoneModel.fromJson(e))
              .toList() ??
          [],
      securityAlerts: (json['securityAlerts'] as List<dynamic>?)
              ?.map((e) => SecurityAlertModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'modelName': modelName,
      'osVersion': osVersion,
      'deviceCode': deviceCode,
      'parentId': parentId,
      'childUserId': childUserId,
      'childName': childName,
      'dailyScreenTimeLimitMinutes': dailyScreenTimeLimitMinutes,
      'usedScreenTimeMinutes': usedScreenTimeMinutes,
      'isLocked': isLocked,
      'batteryLevel': batteryLevel,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'currentAddress': currentAddress,
      'currentNoiseLevel': currentNoiseLevel,
      'isOnline': isOnline,
    };
  }

  int get remainingScreenTimeMinutes {
    final rem = dailyScreenTimeLimitMinutes - usedScreenTimeMinutes;
    return rem > 0 ? rem : 0;
  }
}
