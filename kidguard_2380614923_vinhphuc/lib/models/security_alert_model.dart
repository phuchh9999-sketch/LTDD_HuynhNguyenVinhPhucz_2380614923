class SecurityAlertModel {
  final int id;
  final int childDeviceId;
  final String childName;
  final String alertType; // SOS_MANUAL, HIGH_NOISE_BULLYING, FALL_SHAKE_IMPACT, GEOFENCE_EXIT
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double noiseDecibel;
  final String severity; // Low, Medium, High, Critical
  bool isResolved;
  final DateTime createdAt;

  SecurityAlertModel({
    required this.id,
    required this.childDeviceId,
    required this.childName,
    required this.alertType,
    required this.title,
    required this.description,
    this.latitude = 10.776889,
    this.longitude = 106.700806,
    this.noiseDecibel = 0.0,
    this.severity = 'High',
    this.isResolved = false,
    required this.createdAt,
  });

  factory SecurityAlertModel.fromJson(Map<String, dynamic> json) {
    return SecurityAlertModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      childDeviceId: json['childDeviceId'] is int ? json['childDeviceId'] : int.tryParse(json['childDeviceId'].toString()) ?? 0,
      childName: json['childName'] ?? 'Bé',
      alertType: json['alertType'] ?? 'SOS_MANUAL',
      title: json['title'] ?? 'Cảnh báo',
      description: json['description'] ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 10.776889,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 106.700806,
      noiseDecibel: (json['noiseDecibel'] is num) ? (json['noiseDecibel'] as num).toDouble() : 0.0,
      severity: json['severity'] ?? 'High',
      isResolved: json['isResolved'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childDeviceId': childDeviceId,
      'childName': childName,
      'alertType': alertType,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'noiseDecibel': noiseDecibel,
      'severity': severity,
      'isResolved': isResolved,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
