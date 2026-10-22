class SafeZoneModel {
  final int id;
  final int? childDeviceId;
  String name;
  String address;
  double latitude;
  double longitude;
  double radiusMeters;
  bool isActive;

  SafeZoneModel({
    required this.id,
    this.childDeviceId,
    required this.name,
    this.address = '',
    this.latitude = 10.776889,
    this.longitude = 106.700806,
    this.radiusMeters = 300.0,
    this.isActive = true,
  });

  factory SafeZoneModel.fromJson(Map<String, dynamic> json) {
    return SafeZoneModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      childDeviceId: json['childDeviceId'] != null ? (json['childDeviceId'] is int ? json['childDeviceId'] : int.tryParse(json['childDeviceId'].toString())) : null,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 10.776889,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 106.700806,
      radiusMeters: (json['radiusMeters'] is num) ? (json['radiusMeters'] as num).toDouble() : 300.0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childDeviceId': childDeviceId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
    };
  }
}
