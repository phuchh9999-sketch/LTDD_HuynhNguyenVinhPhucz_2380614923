import 'package:flutter/material.dart';
import '../../models/app_restriction_model.dart';
import '../../models/child_device_model.dart';
import '../../models/habit_quest_model.dart';
import '../../models/safe_zone_model.dart';
import '../../models/security_alert_model.dart';
import '../../services/alert_service.dart';
import '../../services/app_rule_service.dart';
import '../../services/audit_warning_service.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/habit_service.dart';
import '../../services/safe_zone_service.dart';
import '../../widgets/qr_dialog_widget.dart';
import '../auth/login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _currentTabIndex = 0;
  List<ChildDeviceModel> _devices = [];
  ChildDeviceModel? _selectedDevice;
  List<AppRestrictionModel> _apps = [];
  List<SafeZoneModel> _safeZones = [];
  List<SecurityAlertModel> _alerts = [];
  List<HabitQuestModel> _quests = [];
  List<Map<String, dynamic>> _adminWarnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllParentData();
  }

  Future<void> _loadAllParentData() async {
    setState(() => _isLoading = true);
    final currentUser = AuthService.memoryUser;
    List<ChildDeviceModel> devices = [];
    if (currentUser?.id != null && currentUser?.role.toLowerCase() == 'parent') {
      devices = await DeviceService().getDevices(parentId: currentUser!.id);
      if (devices.isEmpty) {
        devices = await DeviceService().getDevices();
      }
    } else {
      devices = await DeviceService().getDevices();
    }
    ChildDeviceModel? activeDev = _selectedDevice;

    if (devices.isNotEmpty) {
      if (activeDev == null || !devices.any((d) => d.id == activeDev?.id)) {
        activeDev = devices.first;
      } else {
        activeDev = devices.firstWhere((d) => d.id == activeDev!.id);
      }
    } else {
      activeDev = null;
    }

    List<AppRestrictionModel> apps = [];
    List<SafeZoneModel> safeZones = [];
    List<HabitQuestModel> quests = [];

    if (activeDev != null) {
      apps = await AppRuleService().getApps(activeDev.id);
      safeZones = await SafeZoneService().getSafeZones(activeDev.id);
      quests = await HabitService().getQuests(activeDev.id);
    }

    final alerts = await AlertService().getAlerts();
    final warnings = await AuditWarningService().getAdminWarnings();

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _selectedDevice = activeDev;
      _apps = apps;
      _safeZones = safeZones;
      _alerts = alerts;
      _quests = quests;
      _adminWarnings = warnings.where((w) => w['isRead'] != true).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadDeviceDetails(ChildDeviceModel dev) async {
    final apps = await AppRuleService().getApps(dev.id);
    final safeZones = await SafeZoneService().getSafeZones(dev.id);
    final quests = await HabitService().getQuests(dev.id);
    setState(() {
      _selectedDevice = dev;
      _apps = apps;
      _safeZones = safeZones;
      _quests = quests;
    });
  }

  // --- CRUD 1: Quản lý Thiết bị con ---
  void _showAddDeviceDialog() {
    final nameCtrl = TextEditingController(text: 'Xiaomi Redmi Note 13');
    final childCtrl = TextEditingController(text: 'Bé Hùng (8 tuổi)');
    final limitCtrl = TextEditingController(text: '120');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm Thiết Bị Con Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên thiết bị (Model máy)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: childCtrl,
              decoration: const InputDecoration(labelText: 'Tên bé sử dụng'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hạn mức sử dụng ngày (Phút)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final limit = int.tryParse(limitCtrl.text) ?? 120;
              final newDev = ChildDeviceModel(
                id: 0,
                deviceName: nameCtrl.text.trim(),
                childName: childCtrl.text.trim(),
                deviceCode: 'KID-${DateTime.now().millisecondsSinceEpoch % 100000}',
                dailyScreenTimeLimitMinutes: limit,
                usedScreenTimeMinutes: 0,
              );
              Navigator.pop(ctx);
              await DeviceService().createDevice(newDev);
              _loadAllParentData();
            },
            child: const Text('Tạo thiết bị & Mã QR'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(ChildDeviceModel dev) {
    final nameCtrl = TextEditingController(text: dev.deviceName);
    final childCtrl = TextEditingController(text: dev.childName);
    final limitCtrl = TextEditingController(text: dev.dailyScreenTimeLimitMinutes.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chỉnh Sửa Thiết Bị'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên thiết bị')),
            const SizedBox(height: 8),
            TextField(controller: childCtrl, decoration: const InputDecoration(labelText: 'Tên bé')),
            const SizedBox(height: 8),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hạn mức ngày (Phút)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              dev.deviceName = nameCtrl.text.trim();
              dev.childName = childCtrl.text.trim();
              dev.dailyScreenTimeLimitMinutes = int.tryParse(limitCtrl.text) ?? dev.dailyScreenTimeLimitMinutes;
              Navigator.pop(ctx);
              await DeviceService().updateDevice(dev);
              _loadAllParentData();
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa thiết bị'),
        content: const Text('Bạn có chắc chắn muốn ngắt kết nối và xóa thiết bị này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DeviceService().deleteDevice(id);
      _loadAllParentData();
    }
  }

  // --- CRUD 2: Quản lý Ứng dụng & Giờ cấm ---
  void _showAddAppDialog() {
    if (_selectedDevice == null) return;
    final nameCtrl = TextEditingController(text: 'Minecraft');
    final catCtrl = TextEditingController(text: 'Trò chơi');
    final limitCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm Ứng Dụng Hạn Chế'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên ứng dụng')),
            const SizedBox(height: 8),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Thể loại (Game, Mạng xã hội...)')),
            const SizedBox(height: 8),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giới hạn thời gian (Phút)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final newApp = AppRestrictionModel(
                id: 0,
                childDeviceId: _selectedDevice!.id,
                appName: nameCtrl.text.trim(),
                category: catCtrl.text.trim(),
                dailyLimitMinutes: int.tryParse(limitCtrl.text) ?? 30,
                isBlocked: false,
              );
              Navigator.pop(ctx);
              await AppRuleService().createApp(newApp);
              _loadDeviceDetails(_selectedDevice!);
            },
            child: const Text('Thêm quy tắc'),
          ),
        ],
      ),
    );
  }

  // --- CRUD 3: Quản lý Vùng an toàn Geofencing ---
  void _showAddSafeZoneDialog() {
    if (_selectedDevice == null) return;
    final nameCtrl = TextEditingController(text: 'Nhà Ông Bà Ngoại');
    final addrCtrl = TextEditingController(text: 'Quận 7, TP. Hồ Chí Minh');
    final radiusCtrl = TextEditingController(text: '350');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm Vùng An Toàn (Geofence)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên vùng (Trường học, Nhà...)')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể')),
            const SizedBox(height: 8),
            TextField(
              controller: radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bán kính an toàn (Mét)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final zone = SafeZoneModel(
                id: 0,
                childDeviceId: _selectedDevice!.id,
                name: nameCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                latitude: _selectedDevice!.currentLatitude,
                longitude: _selectedDevice!.currentLongitude,
                radiusMeters: double.tryParse(radiusCtrl.text) ?? 300.0,
              );
              Navigator.pop(ctx);
              await SafeZoneService().createSafeZone(zone);
              _loadDeviceDetails(_selectedDevice!);
            },
            child: const Text('Tạo vùng an toàn'),
          ),
        ],
      ),
    );
  }

  // --- Tính năng độc quyền 6: Giao nhiệm vụ rèn luyện ---
  void _showAddQuestDialog() {
    if (_selectedDevice == null) return;
    final titleCtrl = TextEditingController(text: 'Đọc 1 chương sách tiếng Anh');
    final descCtrl = TextEditingController(text: 'Đọc và tóm tắt lại 3 từ vựng mới');
    final rewardCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Giao Nhiệm Vụ Rèn Luyện Cho Bé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên nhiệm vụ')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả chi tiết')),
            const SizedBox(height: 8),
            TextField(
              controller: rewardCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Phút thưởng thêm khi hoàn thành'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final quest = HabitQuestModel(
                id: 0,
                childDeviceId: _selectedDevice!.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                rewardMinutes: int.tryParse(rewardCtrl.text) ?? 30,
              );
              Navigator.pop(ctx);
              await HabitService().createQuest(quest);
              _loadDeviceDetails(_selectedDevice!);
            },
            child: const Text('Giao nhiệm vụ'),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF4F46E5),
              radius: 18,
              child: Text('VP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Huỳnh Nguyễn Vĩnh Phúc',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Phụ huynh • Nhóm goddy • 2380614923',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
            onPressed: _loadAllParentData,
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
          : IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildDevicesTab(),
                _buildLocationAndMapTab(),
                _buildAppLimitsTab(),
                _buildAlertsTab(),
                _buildHabitsTab(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        indicatorColor: const Color(0xFFE0E7FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.devices_other_rounded),
            selectedIcon: Icon(Icons.devices_other_rounded, color: Color(0xFF4F46E5)),
            label: 'Thiết bị',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded, color: Color(0xFF4F46E5)),
            label: 'Định vị GPS',
          ),
          NavigationDestination(
            icon: Icon(Icons.app_blocking_outlined),
            selectedIcon: Icon(Icons.app_blocking_rounded, color: Color(0xFF4F46E5)),
            label: 'Khóa App',
          ),
          NavigationDestination(
            icon: Icon(Icons.crisis_alert_rounded),
            selectedIcon: Icon(Icons.crisis_alert_rounded, color: Colors.red),
            label: 'Cảnh báo SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.military_tech_outlined),
            selectedIcon: Icon(Icons.military_tech_rounded, color: Colors.amber),
            label: 'Nhiệm vụ',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: THIẾT BỊ CON & KHÓA TỪ XA ---
  Widget _buildDevicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Danh Sách Thiết Bị Con',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _showAddDeviceDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm thiết bị'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // CẢNH BÁO TỪ QUẢN TRỊ VIÊN (ADMIN) GỬI TỚI PHỤ HUYNH
        if (_adminWarnings.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade800, Colors.deepOrange.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cảnh Báo Từ Quản Trị Viên (Admin)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._adminWarnings.take(2).map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${w['title'] ?? 'Thông báo an toàn'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        w['message'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      for (var w in _adminWarnings) {
                        if (w['id'] != null) {
                          await AuditWarningService().markWarningRead(w['id']);
                        }
                      }
                      setState(() => _adminWarnings.clear());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xác nhận đã đọc cảnh báo của Admin!')),
                      );
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Tôi đã hiểu & tiếp thu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_devices.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có thiết bị nào. Hãy nhấn "+ Thêm thiết bị" để bắt đầu!'),
            ),
          )
        else
          ..._devices.map((dev) {
            final isSelected = _selectedDevice?.id == dev.id;
            final usedRatio = (dev.usedScreenTimeMinutes / dev.dailyScreenTimeLimitMinutes).clamp(0.0, 1.0);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                  width: 2,
                ),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dev.isLocked ? Colors.red.shade50 : const Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            dev.isLocked ? Icons.phonelink_lock_rounded : Icons.phone_android_rounded,
                            color: dev.isLocked ? Colors.red : const Color(0xFF4F46E5),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dev.deviceName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bé: ${dev.childName} • Pin: ${dev.batteryLevel}%',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Nút Quét mã QR ghép đôi thiết bị (Chức năng thuyết trình E)
                        IconButton(
                          icon: const Icon(Icons.qr_code_rounded, color: Color(0xFF4F46E5)),
                          tooltip: 'Mã QR Ghép Đôi',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => QrDisplayDialog(
                                deviceCode: dev.deviceCode,
                                deviceName: dev.deviceName,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Thanh tiến độ thời gian dùng máy hôm nay
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thời gian dùng hôm nay:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        Text(
                          '${dev.usedScreenTimeMinutes} / ${dev.dailyScreenTimeLimitMinutes} phút',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: usedRatio,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          usedRatio > 0.85 ? Colors.redAccent : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Hàng điều khiển: Khóa từ xa & Sửa / Xóa (Wrap Responsive chống 100% lỗi tràn viền)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: dev.isLocked,
                                activeColor: Colors.red,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) async {
                                  final success = await DeviceService().toggleLock(dev.id, val);
                                  if (success) {
                                    setState(() => dev.isLocked = val);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(val ? 'Đã KHÓA máy bé từ xa!' : 'Đã MỞ KHÓA máy cho bé!'),
                                        backgroundColor: val ? Colors.red : Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dev.isLocked ? 'Đang Khóa' : 'Mở Khóa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: dev.isLocked ? Colors.red : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _loadDeviceDetails(dev),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune_rounded, size: 14, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 4),
                                    Text('Chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(5),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Sửa',
                              onPressed: () => _showEditDeviceDialog(dev),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(5),
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'Xóa',
                              onPressed: () => _deleteDevice(dev.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 2: ĐỊNH VỊ GPS THỜI GIAN THỰC & VÙNG AN TOÀN GEOFENCING ---
  Widget _buildLocationAndMapTab() {
    if (_selectedDevice == null) {
      return const Center(child: Text('Vui lòng thêm thiết bị để xem vị trí'));
    }

    final dev = _selectedDevice!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Khung mô phỏng Bản đồ Vị trí Thời Gian Thực (Chức năng thuyết trình B)
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Mô phỏng các tuyến đường bản đồ
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapGridPainter(),
                ),
              ),
              // Vòng tròn bán kính Geofence an toàn
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              // Marker định vị của bé
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: Text(
                        dev.childName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.location_pin, size: 40, color: Colors.redAccent),
                  ],
                ),
              ),
              // Nút refresh vị trí GPS
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  onPressed: () async {
                    await DeviceService().updateLocation(
                      childDeviceId: dev.id,
                      latitude: dev.currentLatitude + 0.0001,
                      longitude: dev.currentLongitude + 0.0001,
                      address: dev.currentAddress,
                    );
                    _loadAllParentData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đồng bộ vị trí GPS thời gian thực!')),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location_rounded, color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Thẻ thông tin địa chỉ GPS hiện tại
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  const Text('Vị trí thực tế của bé:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Live GPS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dev.currentAddress ?? 'Quận 1, TP. Hồ Chí Minh',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Tọa độ: ${dev.currentLatitude.toStringAsFixed(6)}, ${dev.currentLongitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // CRUD 3: Vùng an toàn Geofencing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vùng An Toàn (Geofence)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _showAddSafeZoneDialog,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Thêm vùng'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_safeZones.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có vùng an toàn nào')))
        else
          ..._safeZones.map((zone) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981)),
                ),
                title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${zone.address}\nBán kính an toàn: ${zone.radiusMeters.toInt()}m'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await SafeZoneService().deleteSafeZone(zone.id);
                    _loadDeviceDetails(dev);
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 3: KHÓA APP & GIỚI HẠN THỜI GIAN (CRUD 2) ---
  Widget _buildAppLimitsTab() {
    if (_selectedDevice == null) {
      return const Center(child: Text('Chưa chọn thiết bị'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quy Tắc Giới Hạn Ứng Dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Thiết bị: ${_selectedDevice!.deviceName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            FilledButton.icon(
              onPressed: _showAddAppDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm App'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_apps.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa cấu hình ứng dụng nào')))
        else
          ..._apps.map((app) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: app.isBlocked ? Colors.red.shade100 : Colors.indigo.shade50,
                  child: Icon(
                    app.isBlocked ? Icons.block_rounded : Icons.apps_rounded,
                    color: app.isBlocked ? Colors.red : Colors.indigo,
                  ),
                ),
                title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${app.category} • Giới hạn: ${app.dailyLimitMinutes > 0 ? "${app.dailyLimitMinutes} phút" : "Không giới hạn"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: !app.isBlocked,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                        await AppRuleService().toggleBlock(app.id);
                        _loadDeviceDetails(_selectedDevice!);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () async {
                        await AppRuleService().deleteApp(app.id);
                        _loadDeviceDetails(_selectedDevice!);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 4: TRUNG TÂM CẢNH BÁO SOS & TIẾNG ỒN BẠO LỰC (CRUD 4) ---
  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Trung Tâm Cảnh Báo An Toàn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_alerts.length} sự cố', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 14),

        if (_alerts.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không có cảnh báo nguy hiểm nào!')))
        else
          ..._alerts.map((alert) {
            final isCritical = alert.severity == 'Critical' || alert.severity == 'High';

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: alert.isResolved ? Colors.white : (isCritical ? Colors.red.shade50 : Colors.amber.shade50),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                alert.alertType == 'HIGH_NOISE_BULLYING'
                                    ? Icons.graphic_eq_rounded
                                    : (alert.alertType == 'SOS_MANUAL' ? Icons.sos_rounded : Icons.sports_gymnastics_rounded),
                                color: isCritical ? Colors.red : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isCritical ? Colors.red.shade900 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () async {
                            await AlertService().deleteAlert(alert.id);
                            _loadAllParentData();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(alert.description, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      'Bé: ${alert.childName} • Vị trí: ${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}${alert.noiseDecibel > 0 ? " • Đo được: ${alert.noiseDecibel} dB" : ""}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!alert.isResolved)
                          FilledButton.tonal(
                            onPressed: () async {
                              await AlertService().resolveAlert(alert.id);
                              _loadAllParentData();
                            },
                            child: const Text('Đánh dấu đã xử lý an toàn'),
                          )
                        else
                          const Text('✓ Đã xử lý', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 5: NHIỆM VỤ RÈN LUYỆN ĐỔI GIỜ DÙNG MÁY (TÍNH NĂNG MỚI ĐỘC QUYỀN) ---
  Widget _buildHabitsTab() {
    if (_selectedDevice == null) {
      return const Center(child: Text('Vui lòng chọn thiết bị'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhiệm Vụ Rèn Luyện Thói Quen',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Làm việc nhà & học tập đổi thêm giờ dùng máy',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _showAddQuestDialog,
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Giao việc'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_quests.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa có nhiệm vụ rèn luyện nào')))
        else
          ..._quests.map((quest) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${quest.rewardMinutes} Phút',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(quest.description, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quest.isCompleted ? '✓ Bé đã nộp bài tập' : '⏳ Bé đang thực hiện',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: quest.isCompleted ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (quest.isCompleted && !quest.isApproved)
                          FilledButton(
                            onPressed: () async {
                              final res = await HabitService().approveQuest(quest.id);
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'])),
                                );
                                _loadDeviceDetails(_selectedDevice!);
                              }
                            },
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Duyệt thưởng +Phút'),
                          )
                        else if (quest.isApproved)
                          const Text('Đã duyệt thưởng thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                        else
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () async {
                              await HabitService().deleteQuest(quest.id);
                              _loadDeviceDetails(_selectedDevice!);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3;

    // Draw mock road grid
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), paint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
