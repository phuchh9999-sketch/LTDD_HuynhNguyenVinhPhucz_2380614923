class UserModel {
  final String? id;
  final String username;
  final String? email;
  final String? fullName;
  final String role;
  final String? initials;
  final String? parentId;
  final String? token;

  UserModel({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    this.initials,
    this.parentId,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id']?.toString(),
      username: json['username'] ?? json['userName'] ?? '',
      email: json['email'],
      fullName: json['fullName'] ?? json['name'],
      role: json['role'] ?? 'Parent',
      initials: json['initials'] ?? 'VP',
      parentId: json['parentId']?.toString(),
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'initials': initials,
      'parentId': parentId,
    };
  }
}
