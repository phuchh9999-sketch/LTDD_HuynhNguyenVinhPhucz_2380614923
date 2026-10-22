import 'package:flutter/material.dart';
import '../../models/child_device_model.dart';
import '../../services/audit_warning_service.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../auth/login_screen.dart';
import 'parent_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _users = [];
  List<ChildDeviceModel> _devices = [];
  List<Map<String, dynamic>> _staffReports = [];
  Map<String, dynamic> _systemStats = {};
  String _selectedRoleFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final stats = await AuthService().getSystemStats();
    final users = await AuthService().getAllUsers();
    final devices = await DeviceService().getDevices();
    final reports = await AuditWarningService().getStaffReports();
    setState(() {
      _systemStats = stats;
      _users = users;
      _devices = devices;
      _staffReports = reports;
      _isLoading = false;
    });
  }

  Future<void> _showRoleDialog(Map<String, dynamic> user) async {
    String currentRole = user['role'] ?? 'Parent';
    String selectedRole = currentRole;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Phân quyền cho ${user['userName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Admin (Toàn quyền quản trị)'),
                value: 'Admin',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Staff (Nhân viên kỹ thuật)'),
                value: 'Staff',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Parent (Phụ huynh)'),
                value: 'Parent',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
              RadioListTile<String>(
                title: const Text('Child (Trẻ em)'),
                value: 'Child',
                groupValue: selectedRole,
                onChanged: (val) => setModalState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await AuthService().updateUserRole(user['id'].toString(), selectedRole);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật vai trò thành $selectedRole')),
                  );
                  _loadAdminData();
                }
              },
              child: const Text('Lưu quyền'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final fullNameCtrl = TextEditingController(text: user['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phoneNumber'] ?? '');
    final userNameCtrl = TextEditingController(text: user['userName'] ?? '');
    final passwordCtrl = TextEditingController();
    final bool isAdminAccount = (user['userName'] ?? '').toString().toLowerCase() == 'admin';
    String selectedRole = user['role'] ?? 'Parent';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note_rounded, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chỉnh Sửa: ${user['userName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: fullNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên đầy đủ',
                    prefixIcon: const Icon(Icons.badge_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email liên lạc',
                    prefixIcon: const Icon(Icons.email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: const Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userNameCtrl,
                  enabled: !isAdminAccount,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập (Username)',
                    prefixIcon: const Icon(Icons.person_rounded),
                    helperText: isAdminAccount ? 'Không thể đổi username của tài khoản Admin' : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                if (!isAdminAccount) ...[
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Vai trò (Role)',
                      prefixIcon: const Icon(Icons.security_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Parent', child: Text('Parent (Phụ huynh)')),
                      DropdownMenuItem(value: 'Child', child: Text('Child (Trẻ em)')),
                      DropdownMenuItem(value: 'Staff', child: Text('Staff (Nhân viên kỹ thuật)')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản trị viên)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (Để trống nếu giữ nguyên)',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final res = await AuthService().updateUser(user['id'].toString(), {
                  'fullName': fullNameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phoneNumber': phoneCtrl.text.trim(),
                  'userName': userNameCtrl.text.trim(),
                  'role': selectedRole,
                  if (passwordCtrl.text.trim().isNotEmpty) 'password': passwordCtrl.text.trim(),
                });
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Cập nhật thành công'),
                      backgroundColor: res['success'] ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                }
                _loadAdminData();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu Thay Đổi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteUserDialog(Map<String, dynamic> user) async {
    final String uname = user['userName'] ?? '';
    final String fullName = user['fullName'] ?? uname;
    final String role = user['role'] ?? 'User';
    final bool isAdminAccount = uname.toLowerCase() == 'admin';

    if (isAdminAccount) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Không thể xóa Admin'),
            ],
          ),
          content: const Text('Tài khoản Quản trị viên hệ thống (Admin) là tài khoản chủ chốt và không được phép xóa!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Xác Nhận Xóa Tài Khoản',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản "$fullName" (@$uname, vai trò: $role) khỏi hệ thống không?\n\nToàn bộ dữ liệu thiết bị, lịch sử giám sát và liên kết của người dùng này sẽ được dọn dẹp sạch sẽ.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Xóa Vĩnh Viễn'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final res = await AuthService().deleteUser(user['id'].toString());
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đã xóa tài khoản thành công'),
            backgroundColor: res['success'] ? const Color(0xFF10B981) : Colors.red,
          ),
        );
      }
      _loadAdminData();
    }
  }

  Future<void> _showEditDeviceDialog(ChildDeviceModel device) async {
    final deviceNameCtrl = TextEditingController(text: device.deviceName);
    final childNameCtrl = TextEditingController(text: device.childName);
    final limitCtrl = TextEditingController(text: device.dailyScreenTimeLimitMinutes.toString());
    bool isLocked = device.isLocked;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings_cell_rounded, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Chỉnh Sửa Thiết Bị Giám Sát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: deviceNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên thiết bị (Model)',
                    prefixIcon: const Icon(Icons.smartphone_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: childNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên của bé sử dụng',
                    prefixIcon: const Icon(Icons.child_care_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Giới hạn thời gian màn hình (Phút/ngày)',
                    prefixIcon: const Icon(Icons.timer_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Khóa thiết bị từ xa'),
                  subtitle: Text(isLocked ? 'Thiết bị đang bị khóa' : 'Thiết bị đang mở bình thường'),
                  value: isLocked,
                  activeColor: Colors.red,
                  onChanged: (val) => setModalState(() => isLocked = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                device.deviceName = deviceNameCtrl.text.trim();
                device.childName = childNameCtrl.text.trim();
                device.dailyScreenTimeLimitMinutes = int.tryParse(limitCtrl.text.trim()) ?? device.dailyScreenTimeLimitMinutes;
                device.isLocked = isLocked;
                setState(() => _isLoading = true);
                final ok = await DeviceService().updateDevice(device);
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Cập nhật thiết bị thành công!' : 'Lỗi cập nhật thiết bị'),
                      backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                }
                _loadAdminData();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu Thay Đổi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDeviceDialog(dynamic deviceOrMap) async {
    int devId = 0;
    String devName = '';
    String childName = '';
    String code = '';

    if (deviceOrMap is ChildDeviceModel) {
      devId = deviceOrMap.id;
      devName = deviceOrMap.deviceName;
      childName = deviceOrMap.childName;
      code = deviceOrMap.deviceCode;
    } else if (deviceOrMap is Map) {
      devId = deviceOrMap['id'] is int ? deviceOrMap['id'] : int.tryParse(deviceOrMap['id'].toString()) ?? 0;
      devName = deviceOrMap['deviceName'] ?? 'Thiết bị';
      childName = deviceOrMap['childName'] ?? 'Bé';
      code = deviceOrMap['deviceCode'] ?? '';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phonelink_erase_rounded, color: Colors.red),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Xóa Thiết Bị Giám Sát',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thiết bị "$devName" của bé "$childName"${code.isNotEmpty ? ' (Mã: $code)' : ''} không?\n\nThiết bị sẽ bị ngắt kết nối hoàn toàn khỏi hệ thống quản lý.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Xóa Thiết Bị'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final ok = await DeviceService().deleteDevice(devId);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xóa thiết bị thành công!' : 'Lỗi xóa thiết bị'),
            backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
          ),
        );
      }
      _loadAdminData();
    }
  }

  void _showUserDetailsBottomSheet(Map<String, dynamic> user) {
    final role = user['role'] ?? 'Parent';
    final roleColor = _getRoleColor(role);
    final devices = (user['devices'] as List<dynamic>?) ?? [];
    final quests = (user['quests'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      user['userName']?.substring(0, 2).toUpperCase() ?? 'US',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: roleColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['fullName'] ?? user['userName'] ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          'Tên đăng nhập: ${user['userName']}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: roleColor),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Thông tin đăng ký tài khoản
                  const Text(
                    '1. Thông Tin Đăng Ký Tài Khoản',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Tên đăng nhập (Username)', user['userName'] ?? 'Chưa cập nhật'),
                        const Divider(height: 16),
                        _buildInfoRow('Email đăng ký', user['email'] ?? 'Chưa cập nhật'),
                        const Divider(height: 16),
                        _buildInfoRow('Họ và tên đầy đủ', user['fullName'] ?? 'Chưa cập nhật'),
                        const Divider(height: 16),
                        _buildInfoRow('Số điện thoại', user['phoneNumber'] ?? 'Chưa cập nhật'),
                        const Divider(height: 16),
                        _buildInfoRow('Vai trò hệ thống (Role)', role),
                        const Divider(height: 16),
                        _buildInfoRow('Ngày giờ đăng ký', _formatDate(user['createdAt'])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Danh sách các bé & thiết bị liên kết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. Các Bé & Thiết Bị Liên Kết',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${devices.length} thiết bị bé',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (devices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Tài khoản này chưa liên kết thiết bị bé nào.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    )
                  else
                    ...devices.map((d) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (d['isLocked'] == true) ? Icons.lock_rounded : Icons.phone_android_rounded,
                                color: (d['isLocked'] == true) ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bé: ${d['childName'] ?? 'Chưa đặt tên'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Thiết bị: ${d['deviceName'] ?? 'Điện thoại'} • Pin: ${d['batteryLevel'] ?? 100}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (d['currentAddress'] != null)
                                      Text('Vị trí: ${d['currentAddress']}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (d['isLocked'] == true) ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (d['isLocked'] == true) ? 'Đang khóa' : 'Đang mở',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: (d['isLocked'] == true) ? Colors.red : Colors.green.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Xóa thiết bị',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showDeleteDeviceDialog(d);
                                },
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 20),

                  // 3. Thông tin bài đăng / nhiệm vụ đã đăng tải
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '3. Thông Tin Bài Đăng / Nhiệm Vụ Giao Bé',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${quests.length} bài đăng',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (quests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Tài khoản này chưa đăng bài/nhiệm vụ nào.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    )
                  else
                    ...quests.map((q) {
                      final isFlagged = q['moderationStatus'] == 'Flagged';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFlagged ? const Color(0xFFFFF1F2) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isFlagged ? Colors.red.shade200 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    q['title'] ?? 'Nhiệm vụ',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFlagged ? Colors.red : Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isFlagged ? 'BẤT THƯỜNG' : 'HỢP LỆ',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            if (q['description'] != null && q['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(q['description'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('+${q['rewardMinutes'] ?? 30} phút thưởng', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                Text('Đăng lúc: ${_formatDate(q['createdAt'])}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            if (q['staffNotes'] != null && q['staffNotes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Ghi chú kiểm duyệt: ${q['staffNotes']}', style: TextStyle(fontSize: 11, color: Colors.amber.shade900)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // 4. Các nút hành động
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditUserDialog(user);
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Sửa Thông Tin'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRoleDialog(user);
                        },
                        icon: const Icon(Icons.security_rounded, size: 18),
                        label: const Text('Phân Quyền'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (role.toLowerCase() == 'parent') ...[
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParentDetailScreen(parentUser: user),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text('Xem Lịch Sử'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                      if ((user['userName'] ?? '').toString().toLowerCase() != 'admin') ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showDeleteUserDialog(user);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          label: const Text('Xóa Tài Khoản', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Widget _buildRoleFilterChip(String roleKey, String label) {
    final isSelected = _selectedRoleFilter == roleKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.indigo,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade300),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRoleFilter = roleKey;
          });
        }
      },
    );
  }

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalParents = _systemStats['totalParents'] ??
        _users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'parent').length;
    final int totalKids = _systemStats['totalKids'] ??
        _devices.map((d) => d.childName).toSet().length;
    final int totalStaff = _systemStats['totalStaff'] ??
        _users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'staff').length;
    final int totalAdmins = _systemStats['totalAdmins'] ??
        _users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'admin').length;
    final int totalQuests = _systemStats['totalQuests'] ?? 0;

    final filteredUsers = _selectedRoleFilter == 'All'
        ? _users
        : _users
            .where((u) =>
                (u['role'] ?? '').toString().toLowerCase() == _selectedRoleFilter.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trang Quản Trị Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Admin Portal • Huỳnh Nguyễn Vĩnh Phúc', style: TextStyle(fontSize: 12, color: Colors.indigo)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Cards: Tổng số Phụ Huynh và Bé (Yêu cầu đề tài)
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Tổng Phụ Huynh',
                        value: '$totalParents',
                        icon: Icons.family_restroom_rounded,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Tổng Số Bé',
                        value: '$totalKids',
                        icon: Icons.child_care_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Nhân Viên & Admin',
                        value: '$totalStaff Staff • $totalAdmins Admin',
                        icon: Icons.badge_rounded,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Bài Đăng Nhiệm Vụ',
                        value: '$totalQuests bài',
                        icon: Icons.assignment_turned_in_rounded,
                        color: Colors.pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Thiết Bị Trực Tuyến',
                        value: '${_devices.where((d) => d.isOnline).length}',
                        icon: Icons.wifi_tethering_rounded,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Thiết Bị Bị Khóa',
                        value: '${_devices.where((d) => d.isLocked).length}',
                        icon: Icons.lock_clock_rounded,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // User Management & Profiles Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Thông Tin Đăng Ký Tất Cả Tài Khoản',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredUsers.length}/${_users.length} tài khoản',
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips by Role
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilterChip('All', 'Tất cả (${_users.length})'),
                        const SizedBox(width: 8),
                        _buildRoleFilterChip('Parent', 'Phụ huynh ($totalParents)'),
                        const SizedBox(width: 8),
                        _buildRoleFilterChip('Child', 'Bé ($totalKids)'),
                        const SizedBox(width: 8),
                        _buildRoleFilterChip('Staff', 'Nhân viên ($totalStaff)'),
                        const SizedBox(width: 8),
                        _buildRoleFilterChip('Admin', 'Admin ($totalAdmins)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    color: Colors.white,
                    child: filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Không có tài khoản nào thuộc nhóm này.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final u = filteredUsers[index];
                              final role = u['role'] ?? 'Parent';
                              final childCount = u['childCount'] ?? 0;
                              final questCount = u['postedQuestsCount'] ?? 0;
                              final childrenNames = (u['childrenNames'] as List<dynamic>?) ?? [];

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                onTap: () => _showUserDetailsBottomSheet(u),
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                                  child: Text(
                                    u['userName']?.substring(0, 2).toUpperCase() ?? 'US',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getRoleColor(role),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        u['fullName'] ?? u['userName'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(role).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getRoleColor(role),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text('Tài khoản: ${u['userName']} • Email: ${u['email'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (childrenNames.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '👶 Bé: ${childrenNames.join(', ')} ($childCount thiết bị)',
                                        style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                    if (questCount > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '📝 Đã đăng $questCount nhiệm vụ rèn luyện',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(5),
                                      icon: const Icon(Icons.edit_note_rounded, size: 21, color: Colors.indigo),
                                      tooltip: 'Sửa thông tin',
                                      onPressed: () => _showEditUserDialog(u),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(5),
                                      icon: const Icon(Icons.security_rounded, size: 19, color: Colors.teal),
                                      tooltip: 'Phân quyền',
                                      onPressed: () => _showRoleDialog(u),
                                    ),
                                    if ((u['userName'] ?? '').toString().toLowerCase() != 'admin')
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(5),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.redAccent),
                                        tooltip: 'Xóa tài khoản',
                                        onPressed: () => _showDeleteUserDialog(u),
                                      ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(5),
                                      icon: const Icon(Icons.info_outline_rounded, size: 19, color: Colors.blueGrey),
                                      tooltip: 'Chi tiết',
                                      onPressed: () => _showUserDetailsBottomSheet(u),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  // BÁO CÁO SỰ CỐ TỪ NHÂN VIÊN GỬI LÊN ADMIN (YÊU CẦU ĐỀ TÀI)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.report_problem_rounded, color: Colors.deepOrange, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Báo Cáo Sự Cố Từ Nhân Viên Kỹ Thuật',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: Text(
                          '${_staffReports.length} báo cáo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhân viên kiểm tra và báo cáo các hành vi bất thường của phụ huynh/trẻ em để Admin xử lý & cảnh báo.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  if (_staffReports.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 0,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có báo cáo sự cố nào từ nhân viên', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _staffReports.length,
                      itemBuilder: (context, index) {
                        final r = _staffReports[index];
                        final title = r['title']?.toString() ?? 'Sự cố';
                        final reason = r['reason']?.toString() ?? '';
                        final staffName = r['staffName']?.toString() ?? 'Nhân viên';
                        final parentName = r['parentName']?.toString() ?? 'Phụ huynh';
                        final childName = r['childName']?.toString() ?? 'Trẻ em';
                        final severity = r['severity']?.toString() ?? 'Warning';

                        final isCrit = severity == 'Critical';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: isCrit ? const Color(0xFFFFF1F2) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCrit ? Colors.red : Colors.orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCrit ? 'NGHIÊM TRỌNG' : 'CẢNH BÁO',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bởi: $staffName • Đối tượng: $parentName (Bé $childName)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reason,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      // Tìm phụ huynh để mở màn hình chi tiết & phát cảnh báo
                                      final pUser = _users.firstWhere(
                                        (u) => u['id'] == r['parentId'] || u['fullName'] == parentName,
                                        orElse: () => {
                                          'id': r['parentId'] ?? 'parent_default',
                                          'fullName': parentName,
                                          'userName': parentName,
                                          'email': 'parent@gmail.com',
                                          'role': 'Parent'
                                        },
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ParentDetailScreen(parentUser: pUser),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.notifications_active_rounded, size: 16),
                                    label: const Text('Xem xét & Phát Cảnh Báo Phụ Huynh', style: TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isCrit ? Colors.red.shade700 : Colors.orange.shade800,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Global Device List
                  const Text(
                    'Toàn bộ Thiết bị Giám sát Trong Hệ Thống',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    color: Colors.white,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = _devices[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: d.isLocked ? Colors.red.shade50 : Colors.indigo.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              d.isLocked ? Icons.phonelink_lock_rounded : Icons.smartphone_rounded,
                              color: d.isLocked ? Colors.red : Colors.indigo,
                            ),
                          ),
                          title: Text(d.deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Bé: ${d.childName} • Mã QR: ${d.deviceCode}\nĐịa chỉ: ${d.currentAddress ?? 'Quận 1, TP. HCM'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${d.batteryLevel}% Pin',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.indigo),
                                tooltip: 'Sửa thiết bị',
                                onPressed: () => _showEditDeviceDialog(d),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Xóa thiết bị',
                                onPressed: () => _showDeleteDeviceDialog(d),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'staff':
        return Colors.blue;
      case 'child':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
