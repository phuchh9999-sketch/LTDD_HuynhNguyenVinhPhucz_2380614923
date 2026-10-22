import 'package:flutter/material.dart';
import '../../models/child_device_model.dart';
import '../../services/audit_warning_service.dart';
import '../../services/device_service.dart';

class ParentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> parentUser;

  const ParentDetailScreen({
    super.key,
    required this.parentUser,
  });

  @override
  State<ParentDetailScreen> createState() => _ParentDetailScreenState();
}

class _ParentDetailScreenState extends State<ParentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChildDeviceModel> _devices = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _warnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadParentDetailData();
  }

  Future<void> _loadParentDetailData() async {
    setState(() => _isLoading = true);
    final parentId = widget.parentUser['id']?.toString() ?? '';

    final devices = await DeviceService().getDevices(parentId: parentId);
    final logs = await AuditWarningService().getParentAuditLogs(parentId);
    final warnings = await AuditWarningService().getAdminWarnings(parentId);

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _auditLogs = logs;
      _warnings = warnings;
      _isLoading = false;
    });
  }

  void _showSendWarningDialog([String? defaultTitle, String? defaultMessage]) {
    final titleCtrl = TextEditingController(text: defaultTitle ?? 'Nhắc nhở kiểm tra an toàn cho con');
    final messageCtrl = TextEditingController(
      text: defaultMessage ?? 'Hệ thống nhận thấy con trẻ có thời gian sử dụng thiết bị kéo dài hoặc cảnh báo âm thanh bất thường. Đề nghị phụ huynh kiểm tra.',
    );
    String selectedSeverity = 'Warning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Gửi Cảnh Báo Cho Phụ Huynh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gửi tới: ${widget.parentUser['fullName'] ?? widget.parentUser['userName']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                ),
                const SizedBox(height: 12),
                const Text('Mẫu cảnh báo nhanh:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Quá giờ dùng', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          titleCtrl.text = 'Cảnh báo thời lượng sử dụng vượt mức';
                          messageCtrl.text = 'Bé đã dùng máy vượt quá hạn mức quy định hôm nay. Đề nghị phụ huynh khóa máy hoặc điều chỉnh hạn mức hợp lý.';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Tiếng ồn / Bắt nạt', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          titleCtrl.text = 'Cảnh báo tiếng ồn lớn & Nguy cơ bắt nạt';
                          messageCtrl.text = 'Cảm biến âm thanh phát hiện âm lượng vượt ngưỡng 85 dB liên tục xung quanh vị trí của bé. Đề nghị phụ huynh kiểm tra ngay!';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Nhiệm vụ chưa chuẩn', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          titleCtrl.text = 'Nhắc nhở về nhiệm vụ rèn luyện giao cho con';
                          messageCtrl.text = 'Ban kiểm duyệt nhận thấy nội dung nhiệm vụ phụ huynh giao có dấu hiệu ép buộc quá mức. Đề nghị điều chỉnh lại cho phù hợp tâm sinh lý lứa tuổi.';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề cảnh báo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung chi tiết nhắc nhở / cảnh báo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(labelText: 'Mức độ cảnh báo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Notice', child: Text('Nhắc nhở (Notice)')),
                    DropdownMenuItem(value: 'Warning', child: Text('Cảnh báo (Warning)')),
                    DropdownMenuItem(value: 'Urgent', child: Text('Khẩn cấp (Urgent)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSeverity = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton.icon(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final msg = messageCtrl.text.trim();
                if (title.isEmpty || msg.isEmpty) return;

                Navigator.pop(ctx);
                final parentId = widget.parentUser['id']?.toString() ?? '';
                final parentName = widget.parentUser['fullName']?.toString() ?? widget.parentUser['userName']?.toString();

                final success = await AuditWarningService().sendAdminWarning(
                  parentId: parentId,
                  parentName: parentName,
                  title: title,
                  message: msg,
                  severity: selectedSeverity,
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi thông báo cảnh báo tới phụ huynh $parentName thành công!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  _loadParentDetailData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể gửi cảnh báo. Vui lòng thử lại.')),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Gửi Cảnh Báo Ngay'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentName = widget.parentUser['fullName'] ?? widget.parentUser['userName'] ?? 'Phụ huynh';
    final username = widget.parentUser['userName'] ?? '';
    final email = widget.parentUser['email'] ?? 'Chưa cập nhật';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_rounded, color: Colors.orange),
            tooltip: 'Phát cảnh báo cho phụ huynh này',
            onPressed: () => _showSendWarningDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadParentDetailData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          indicatorColor: const Color(0xFF4F46E5),
          tabs: [
            Tab(
              icon: const Icon(Icons.history_rounded),
              text: 'Lịch sử thêm & xóa (${_auditLogs.length})',
            ),
            Tab(
              icon: const Icon(Icons.phone_android_rounded),
              text: 'Thiết bị con (${_devices.length})',
            ),
            Tab(
              icon: const Icon(Icons.notifications_active_outlined),
              text: 'Cảnh báo đã gửi (${_warnings.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header tóm tắt hồ sơ phụ huynh
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: Colors.white,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
                        child: Text(
                          username.length > 2 ? username.substring(0, 2).toUpperCase() : 'PH',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Tên đăng nhập: $username • $email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showSendWarningDialog(),
                        icon: const Icon(Icons.warning_amber_rounded, size: 16),
                        label: const Text('Cảnh báo', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAuditLogsTab(),
                      _buildDevicesTab(),
                      _buildWarningsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- TAB 1: LỊCH SỬ THÊM VÀ XÓA CỦA PHỤ HUYNH (YÊU CẦU ĐỀ TÀI) ---
  Widget _buildAuditLogsTab() {
    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa ghi nhận lịch sử thêm/xóa nào của phụ huynh này', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final actionType = log['actionType']?.toString() ?? 'ACTION';
        final targetName = log['targetName']?.toString() ?? '';
        final details = log['details']?.toString() ?? '';
        final createdAt = log['createdAt']?.toString() ?? '';

        final meta = _getActionMeta(actionType);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: meta['color'].withOpacity(0.12),
                  child: Icon(meta['icon'], color: meta['color'], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: meta['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              meta['label'],
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: meta['color']),
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        targetName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: DANH SÁCH THIẾT BỊ CON CỦA PHỤ HUYNH ---
  Widget _buildDevicesTab() {
    if (_devices.isEmpty) {
      return const Center(child: Text('Phụ huynh này chưa kích hoạt thiết bị con nào', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final d = _devices[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: d.isLocked ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(d.isLocked ? Icons.lock : Icons.phone_android, color: d.isLocked ? Colors.red : Colors.green),
            ),
            title: Text(d.childName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${d.deviceName} • Mã: ${d.deviceCode}\nPin: ${d.batteryLevel}% • ${d.isLocked ? "ĐANG KHÓA" : "Đang hoạt động"}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(d.isOnline ? 'Online' : 'Offline', style: TextStyle(color: d.isOnline ? Colors.green : Colors.grey, fontSize: 11)),
              backgroundColor: d.isOnline ? Colors.green.shade50 : Colors.grey.shade100,
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: DANH SÁCH CẢNH BÁO ADMIN ĐÃ GỬI ---
  Widget _buildWarningsTab() {
    if (_warnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Chưa có cảnh báo nào gửi cho phụ huynh này', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showSendWarningDialog(),
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Gửi cảnh báo đầu tiên'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _warnings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final w = _warnings[index];
        final title = w['title']?.toString() ?? '';
        final msg = w['message']?.toString() ?? '';
        final isRead = w['isRead'] == true;
        final createdAt = w['createdAt']?.toString() ?? '';

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 6),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Chip(
                      label: Text(isRead ? 'Đã xem' : 'Chưa đọc', style: TextStyle(fontSize: 10, color: isRead ? Colors.green : Colors.red)),
                      backgroundColor: isRead ? Colors.green.shade50 : Colors.red.shade50,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Text('Thời gian: ${_formatDate(createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getActionMeta(String actionType) {
    switch (actionType) {
      case 'ADD_DEVICE':
        return {'label': 'THÊM THIẾT BỊ', 'color': Colors.green, 'icon': Icons.add_to_home_screen_rounded};
      case 'DELETE_DEVICE':
        return {'label': 'XÓA THIẾT BỊ', 'color': Colors.red, 'icon': Icons.phonelink_erase_rounded};
      case 'LOCK_DEVICE':
        return {'label': 'KHÓA MÁY', 'color': Colors.deepOrange, 'icon': Icons.lock_rounded};
      case 'UNLOCK_DEVICE':
        return {'label': 'MỞ KHÓA MÁY', 'color': Colors.blue, 'icon': Icons.lock_open_rounded};
      case 'ADD_SAFE_ZONE':
        return {'label': 'THÊM VÙNG AN TOÀN', 'color': Colors.teal, 'icon': Icons.add_location_alt_rounded};
      case 'DELETE_SAFE_ZONE':
        return {'label': 'XÓA VÙNG AN TOÀN', 'color': Colors.pink, 'icon': Icons.wrong_location_rounded};
      case 'ADD_QUEST':
        return {'label': 'GIAO NHIỆM VỤ', 'color': Colors.indigo, 'icon': Icons.assignment_add};
      case 'DELETE_QUEST':
        return {'label': 'XÓA NHIỆM VỤ', 'color': Colors.grey, 'icon': Icons.assignment_late_outlined};
      default:
        return {'label': actionType, 'color': Colors.blueGrey, 'icon': Icons.history};
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}
