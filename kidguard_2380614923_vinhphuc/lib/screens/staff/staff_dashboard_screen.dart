import 'package:flutter/material.dart';
import '../../models/child_device_model.dart';
import '../../models/security_alert_model.dart';
import '../../services/alert_service.dart';
import '../../services/audit_warning_service.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../auth/login_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  List<SecurityAlertModel> _alerts = [];
  List<ChildDeviceModel> _devices = [];
  List<Map<String, dynamic>> _habitQuests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    final alerts = await AlertService().getAlerts();
    final devices = await DeviceService().getDevices();
    final quests = await AuditWarningService().getAllHabitQuests();

    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _devices = devices;
      _habitQuests = quests;
      _isLoading = false;
    });
  }

  Future<void> _handleResolve(int alertId) async {
    final success = await AlertService().resolveAlert(alertId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhân viên đã tiếp nhận & xử lý xong cảnh báo!')),
      );
      _loadStaffData();
    }
  }

  Future<void> _toggleDeviceLock(ChildDeviceModel device) async {
    final newStatus = !device.isLocked;
    final success = await DeviceService().toggleLock(device.id, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Đã hỗ trợ KHÓA thiết bị ${device.deviceName} từ xa'
              : 'Đã hỗ trợ MỞ KHÓA thiết bị ${device.deviceName}'),
        ),
      );
      _loadStaffData();
    }
  }

  // --- 1. NHÂN VIÊN KIỂM TRA NHIỆM VỤ PHỤ HUYNH GIAO CHO BÉ CÓ ĐÚNG MỰC HAY KHÔNG ---
  void _showModerateQuestDialog(Map<String, dynamic> quest) {
    final questId = quest['id'] as int;
    final title = quest['title']?.toString() ?? 'Nhiệm vụ';
    final desc = quest['description']?.toString() ?? '';
    final childName = quest['childDevice'] != null
        ? quest['childDevice']['childName']?.toString() ?? 'Bé'
        : 'Bé';

    String selectedStatus = quest['moderationStatus'] == 'Flagged' ? 'Flagged' : 'Approved';
    final notesCtrl = TextEditingController(text: quest['staffNotes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.fact_check_rounded, color: Colors.indigo, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text('Kiểm Duyệt Tính Đúng Mực Nhiệm Vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nhiệm vụ: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Mô tả: ${desc.isNotEmpty ? desc : "Không có mô tả"}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('Đối tượng: $childName • Thưởng: +${quest['rewardMinutes']} phút', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                const SizedBox(height: 16),
                const Text('Đánh giá của nhân viên kiểm duyệt:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Hợp chuẩn / Đúng mực (Approved)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                  subtitle: const Text('Nhiệm vụ lành mạnh, mang tính giáo dục và phù hợp với lứa tuổi', style: TextStyle(fontSize: 11)),
                  value: 'Approved',
                  groupValue: selectedStatus,
                  onChanged: (val) => setModalState(() => selectedStatus = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Không đúng mực / Cần xem xét (Flagged)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text('Có dấu hiệu bắt phạt, ép buộc quá tải hoặc nội dung không phù hợp', style: TextStyle(fontSize: 11)),
                  value: 'Flagged',
                  groupValue: selectedStatus,
                  onChanged: (val) => setModalState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú kiểm duyệt của nhân viên',
                    hintText: 'Ví dụ: Nhiệm vụ phù hợp hoặc Nhiệm vụ học quá 5 tiếng',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await AuditWarningService().moderateHabitQuest(
                  questId,
                  selectedStatus,
                  notesCtrl.text.trim(),
                );
                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(selectedStatus == 'Approved'
                          ? 'Đã xác nhận nhiệm vụ hợp chuẩn đúng mực!'
                          : 'Đã gắn cờ cảnh báo: Nhiệm vụ có dấu hiệu không đúng mực!'),
                      backgroundColor: selectedStatus == 'Approved' ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  );

                  // Nếu Flagged, gợi ý nhân viên báo cáo luôn lên Admin
                  if (selectedStatus == 'Flagged') {
                    _showReportToAdminDialog(
                      'Phụ huynh của $childName',
                      childName,
                      'Nhiệm vụ "$title" có dấu hiệu không đúng mực: ${notesCtrl.text.trim()}',
                    );
                  }

                  _loadStaffData();
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Lưu Đánh Giá'),
              style: FilledButton.styleFrom(
                backgroundColor: selectedStatus == 'Approved' ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. KHI GẶP LỖI / HÀNH ĐỘNG BẤT THƯỜNG CỦA PHỤ HUYNH & BÉ -> NHÂN VIÊN BÁO CHO ADMIN ---
  void _showReportToAdminDialog([String? defaultParent, String? defaultChild, String? defaultReason]) {
    final parentCtrl = TextEditingController(text: defaultParent ?? 'Huỳnh Nguyễn Vĩnh Phúc');
    final childCtrl = TextEditingController(text: defaultChild ?? 'Bé Nam');
    final titleCtrl = TextEditingController(text: 'Phát hiện hành vi / sự cố bất thường');
    final reasonCtrl = TextEditingController(
      text: defaultReason ?? 'Phát hiện phụ huynh liên tục khóa máy của bé vào khung giờ học hoặc có âm thanh vượt ngưỡng 85dB kéo dài nhưng phụ huynh không phản hồi.',
    );
    String selectedSeverity = 'Warning';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.report_problem_rounded, color: Colors.deepOrange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Báo Cáo Sự Cố Cho Admin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Báo cáo các hành vi bất thường của phụ huynh/trẻ em hoặc sự cố kỹ thuật lên Quản trị viên để Admin phát thông báo cảnh báo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề sự cố / Hành vi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: parentCtrl,
                        decoration: const InputDecoration(labelText: 'Tên phụ huynh', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: childCtrl,
                        decoration: const InputDecoration(labelText: 'Tên của bé', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết hành vi bất thường / lý do',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(labelText: 'Mức độ nghiêm trọng', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Warning', child: Text('Cảnh báo (Warning)')),
                    DropdownMenuItem(value: 'Critical', child: Text('Nghiêm trọng (Critical - Cần Admin can thiệp ngay)')),
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
                final reason = reasonCtrl.text.trim();
                if (title.isEmpty || reason.isEmpty) return;

                Navigator.pop(ctx);
                final success = await AuditWarningService().createStaffReport(
                  title: title,
                  reason: reason,
                  severity: selectedSeverity,
                  parentName: parentCtrl.text.trim(),
                  childName: childCtrl.text.trim(),
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text('Đã gửi báo cáo sự cố lên Quản Trị Viên (Admin) thành công!')),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể gửi báo cáo. Vui lòng thử lại.')),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Gửi Báo Cáo Cho Admin'),
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade800),
            ),
          ],
        ),
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
    final unresolvedCount = _alerts.where((a) => !a.isResolved).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Nhân Viên Hỗ Trợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Kỹ thuật viên & An toàn trẻ em • goddy', style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadStaffData),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportToAdminDialog(),
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('Báo Cáo Cho Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStaffData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner thông báo sự cố
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: unresolvedCount > 0
                            ? [Colors.red.shade600, Colors.red.shade800]
                            : [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            unresolvedCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unresolvedCount > 0
                                    ? '$unresolvedCount Sự cố Khẩn Cấp Cần Tiếp Nhận!'
                                    : 'Hệ thống an toàn - Không có sự cố tồn đọng',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Theo dõi tín hiệu SOS, bạo lực học đường và hỗ trợ gia đình',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== 1. KIỂM DUYỆT NHIỆM VỤ PHỤ HUYNH GIAO CHO BÉ ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.fact_check_rounded, color: Colors.indigo, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Kiểm Duyệt Nhiệm Vụ Phụ Huynh Giao',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${_habitQuests.length} nhiệm vụ',
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kiểm tra các nhiệm vụ rèn luyện xem có đúng mực, an toàn và phù hợp lứa tuổi hay không.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  if (_habitQuests.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 0,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có nhiệm vụ nào được giao trên hệ thống', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _habitQuests.length,
                      itemBuilder: (context, index) {
                        final q = _habitQuests[index];
                        final title = q['title']?.toString() ?? 'Nhiệm vụ';
                        final desc = q['description']?.toString() ?? '';
                        final reward = q['rewardMinutes'] ?? 30;
                        final isApproved = q['isApproved'] == true;
                        final modStatus = q['moderationStatus']?.toString() ?? 'Approved';
                        final staffNotes = q['staffNotes']?.toString() ?? '';
                        final childName = q['childDevice'] != null
                            ? q['childDevice']['childName']?.toString() ?? 'Bé'
                            : 'Bé';

                        final isFlagged = modStatus == 'Flagged';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: isFlagged ? const Color(0xFFFEF2F2) : Colors.white,
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
                                        color: isFlagged ? Colors.red.shade100 : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isFlagged ? Icons.warning_rounded : Icons.verified_rounded,
                                            size: 14,
                                            color: isFlagged ? Colors.red.shade800 : Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isFlagged ? 'CẦN XEM XÉT' : 'HỢP CHUẨN ĐÚNG MỰC',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isFlagged ? Colors.red.shade800 : Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+$reward phút',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Giao cho: $childName • Trạng thái hoàn thành: ${isApproved ? "Đã duyệt thưởng" : "Chưa hoàn thành"}',
                                  style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w500),
                                ),
                                if (staffNotes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isFlagged ? Colors.red.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Ghi chú nhân viên: $staffNotes',
                                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isFlagged ? Colors.red.shade900 : Colors.black87),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showModerateQuestDialog(q),
                                      icon: const Icon(Icons.rule_rounded, size: 16),
                                      label: const Text('Kiểm duyệt tính đúng mực', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: () => _showReportToAdminDialog(
                                        'Phụ huynh của $childName',
                                        childName,
                                        'Hành vi giao nhiệm vụ "$title" cần Admin kiểm tra',
                                      ),
                                      icon: const Icon(Icons.report_problem_rounded, size: 16),
                                      label: const Text('Báo Admin', style: TextStyle(fontSize: 12)),
                                      style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // ==================== 2. CẢNH BÁO AN TOÀN & SOS TỪ THIẾT BỊ ====================
                  const Text('Danh Sách Cảnh Báo An Toàn & SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_alerts.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Chưa có cảnh báo nào')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final a = _alerts[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: a.isResolved ? Colors.white : const Color(0xFFFEF2F2),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: a.isResolved ? Colors.grey : Colors.red, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: a.isResolved ? Colors.black87 : Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        a.isResolved ? 'Đã xử lý' : 'MỚI',
                                        style: TextStyle(
                                          color: a.isResolved ? Colors.green : Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: a.isResolved ? Colors.green.shade50 : Colors.red.shade100,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(a.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                const SizedBox(height: 8),
                                Text(
                                  'Bé: ${a.childName} • Mức âm thanh: ${a.noiseDecibel} dB • Mức độ: ${a.severity}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () => _showReportToAdminDialog(
                                        'Phụ huynh của ${a.childName}',
                                        a.childName,
                                        'Cảnh báo: ${a.title} - ${a.description}',
                                      ),
                                      icon: const Icon(Icons.campaign_outlined, size: 16),
                                      label: const Text('Báo lên Admin', style: TextStyle(fontSize: 12)),
                                      style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade100, foregroundColor: Colors.orange.shade900),
                                    ),
                                    if (!a.isResolved) ...[
                                      const SizedBox(width: 8),
                                      FilledButton.tonalIcon(
                                        onPressed: () => _handleResolve(a.id),
                                        icon: const Icon(Icons.check_rounded, size: 18),
                                        label: const Text('Tiếp nhận & Đóng ticket'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // ==================== 3. HỖ TRỢ KỸ THUẬT THIẾT BỊ TỪ XA ====================
                  const Text('Hỗ Trợ Kỹ Thuật Thiết Bị Khách Hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 0,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = _devices[index];
                        return ListTile(
                          title: Text(d.deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Bé: ${d.childName} • Hạn mức: ${d.dailyScreenTimeLimitMinutes} phút\nTrạng thái: ${d.isLocked ? "Đang bị khóa" : "Đang mở"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => _toggleDeviceLock(d),
                                style: FilledButton.styleFrom(
                                  backgroundColor: d.isLocked ? Colors.green.shade100 : Colors.red.shade100,
                                  foregroundColor: d.isLocked ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                                child: Text(d.isLocked ? 'Mở khóa' : 'Khóa từ xa'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.deepOrange),
                                tooltip: 'Báo cáo thiết bị bất thường cho Admin',
                                onPressed: () => _showReportToAdminDialog(
                                  'Phụ huynh của ${d.childName}',
                                  d.childName,
                                  'Thiết bị ${d.deviceName} có biểu hiện hoạt động bất thường (Pin: ${d.batteryLevel}%, Khóa: ${d.isLocked})',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
