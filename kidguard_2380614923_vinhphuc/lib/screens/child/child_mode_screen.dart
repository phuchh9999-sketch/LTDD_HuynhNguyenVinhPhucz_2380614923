import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/child_device_model.dart';
import '../../models/habit_quest_model.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/habit_service.dart';
import '../../widgets/noise_meter_widget.dart';
import '../auth/login_screen.dart';

class ChildModeScreen extends StatefulWidget {
  const ChildModeScreen({super.key});

  @override
  State<ChildModeScreen> createState() => _ChildModeScreenState();
}

class _ChildModeScreenState extends State<ChildModeScreen> {
  ChildDeviceModel? _currentDevice;
  List<HabitQuestModel> _quests = [];
  bool _isLoading = true;

  // Cảm biến đo tiếng ồn & phát hiện bạo lực học đường (Chức năng thuyết trình D & Tính năng độc quyền)
  double _currentDecibel = 42.0;
  bool _isMicActive = true;
  Timer? _noiseTimer;
  Timer? _deviceSyncTimer; // Timer đồng bộ trạng thái khóa máy từ xa độc lập

  // Cảm biến chuyển động & gia tốc rung chấn THẬT (Chức năng thuyết trình D)
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.8;
  double _accelerometerG = 9.8;
  bool _isRealSensorActive = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeAlertTime;

  // Thông tin pin & đồng hồ thời gian thực của điện thoại
  final Battery _battery = Battery();
  int _currentBatteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batterySubscription;
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadChildDevice();
    _startDeviceSyncTimer();
    _startNoiseSimulation();
    _initBattery();
    _startClock();
    _initRealAccelerometer();
  }

  @override
  void dispose() {
    _deviceSyncTimer?.cancel();
    _noiseTimer?.cancel();
    _clockTimer?.cancel();
    _batterySubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _currentBatteryLevel = level;
        });
      }
    } catch (e) {
      debugPrint('Lỗi đọc % pin thiết bị: $e');
    }

    _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
      try {
        final level = await _battery.batteryLevel;
        if (mounted) {
          setState(() {
            _currentBatteryLevel = level;
            _batteryState = state;
          });
        }
      } catch (_) {}
    });
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadChildDevice() async {
    setState(() => _isLoading = true);
    final user = AuthService.memoryUser;
    final devices = await DeviceService().getDevices();
    if (devices.isNotEmpty) {
      if (user?.id != null) {
        _currentDevice = devices.firstWhere(
          (d) => d.childUserId == user!.id,
          orElse: () => devices.firstWhere(
            (d) => user!.fullName != null && d.childName.toLowerCase().contains(user!.fullName!.toLowerCase()),
            orElse: () => devices.first,
          ),
        );
      } else {
        _currentDevice = devices.first;
      }
      _quests = await HabitService().getQuests(_currentDevice!.id);
    }
    setState(() => _isLoading = false);
  }

  // Đồng bộ trạng thái khóa máy và thời gian dùng máy từ SQL Server mỗi 2 giây (Realtime Remote Lock)
  void _startDeviceSyncTimer() {
    _deviceSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _currentDevice == null) return;
      DeviceService().getDevices().then((devices) {
        if (devices.isNotEmpty && mounted) {
          final updated = devices.firstWhere(
            (d) => d.id == _currentDevice!.id,
            orElse: () => devices.first,
          );
          if (updated.isLocked != _currentDevice!.isLocked ||
              updated.dailyScreenTimeLimitMinutes != _currentDevice!.dailyScreenTimeLimitMinutes ||
              updated.usedScreenTimeMinutes != _currentDevice!.usedScreenTimeMinutes) {
            setState(() {
              _currentDevice = updated;
            });
          }
        }
      }).catchError((_) {});
    });
  }

  void _startNoiseSimulation() {
    final random = Random();
    _noiseTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isMicActive || _currentDevice == null) return;

      // Mô phỏng dao động âm thanh tự nhiên của môi trường (38dB - 55dB)
      double newDecibel = 40.0 + random.nextDouble() * 18.0;

      // Cập nhật lên WebAPI định kỳ
      if (timer.tick % 5 == 0) {
        DeviceService().updateLocation(
          childDeviceId: _currentDevice!.id,
          latitude: _currentDevice!.currentLatitude,
          longitude: _currentDevice!.currentLongitude,
          noiseDecibel: newDecibel,
          batteryLevel: _currentBatteryLevel,
        );
      }

      setState(() {
        _currentDecibel = double.parse(newDecibel.toStringAsFixed(1));
      });
    });
  }

  // Kích hoạt thủ công tiếng ồn lớn / Nguy cơ bạo lực để test hệ thống
  Future<void> _simulateHighNoiseBullyingIncident() async {
    setState(() {
      _currentDecibel = 91.5;
    });

    if (_currentDevice == null) return;

    final res = await AlertService().triggerAlert(
      childDeviceId: _currentDevice!.id,
      alertType: 'HIGH_NOISE_BULLYING',
      title: '🚨 Phát Hiện Tiếng Ồn Đột Biến & Nguy Cơ Bắt Nạt',
      description: 'Micro ghi nhận âm thanh môi trường xung quanh đạt 91.5 dB (tiếng la hét/xô xát) trong hơn 10 giây!',
      latitude: _currentDevice!.currentLatitude,
      longitude: _currentDevice!.currentLongitude,
      noiseDecibel: 91.5,
      severity: 'Critical',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.crisis_alert_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Smart AI Bullying Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Đã tự động gửi thông báo khẩn cấp kèm tọa độ GPS về điện thoại của Cha Mẹ và Trung tâm Giám sát!',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  // Khởi động lắng nghe CẢM BIẾN GIA TỐC PHẦN CỨNG THẬT CỦA ĐIỆN THOẠI (Chức năng thuyết trình D)
  void _initRealAccelerometer() {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (!mounted) return;

          setState(() {
            _accelX = event.x;
            _accelY = event.y;
            _accelZ = event.z;
            _accelerometerG = magnitude;
            _isRealSensorActive = true;
          });

          // Ngưỡng phát hiện rung chấn mạnh / rơi máy / té ngã thật:
          // Khi gia tốc đột biến vượt ngưỡng 24.0 m/s^2 (khoảng 2.5G)
          if (magnitude > 24.0) {
            final now = DateTime.now();
            if (_lastShakeAlertTime == null || now.difference(_lastShakeAlertTime!).inSeconds > 6) {
              _lastShakeAlertTime = now;
              _handleRealShakeDetected(magnitude, event.x, event.y, event.z);
            }
          }
        },
        onError: (e) {
          debugPrint('Lỗi cảm biến gia tốc phần cứng: $e');
          if (mounted) setState(() => _isRealSensorActive = false);
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Không thể kết nối cảm biến gia tốc: $e');
      _isRealSensorActive = false;
    }
  }

  // Xử lý khi phát hiện rung chấn / lắc mạnh thật từ cảm biến phần cứng
  Future<void> _handleRealShakeDetected(double magnitude, double x, double y, double z) async {
    if (_currentDevice == null) return;

    final title = '💥 Cảnh Báo Té Ngã / Rung Chấn Gia Tốc THẬT';
    final desc = 'Cảm biến gia tốc phần cứng phát hiện rung chấn mạnh ${magnitude.toStringAsFixed(1)} m/s² (X: ${x.toStringAsFixed(1)}, Y: ${y.toStringAsFixed(1)}, Z: ${z.toStringAsFixed(1)})!';

    await AlertService().triggerAlert(
      childDeviceId: _currentDevice!.id,
      alertType: 'FALL_SHAKE_IMPACT',
      title: title,
      description: desc,
      latitude: _currentDevice!.currentLatitude,
      longitude: _currentDevice!.currentLongitude,
      noiseDecibel: _currentDecibel,
      severity: 'Critical',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.crisis_alert_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'PHÁT HIỆN RUNG CHẤN THẬT: ${magnitude.toStringAsFixed(1)} m/s²! Đã gửi tín hiệu tới Cha Mẹ.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Kích hoạt thủ công gia tốc rung lắc dữ dội hoặc rơi máy té ngã (hỗ trợ máy ảo/chấm thi)
  Future<void> _simulateFallImpactIncident() async {
    setState(() {
      _accelX = 14.5;
      _accelY = 18.2;
      _accelZ = 19.8;
      _accelerometerG = 28.5; // Đột biến gia tốc
    });

    if (_currentDevice == null) return;

    await AlertService().triggerAlert(
      childDeviceId: _currentDevice!.id,
      alertType: 'FALL_SHAKE_IMPACT',
      title: '💥 Cảnh Báo Té Ngã / Va Chạm Gia Tốc Mạnh',
      description: 'Cảm biến chuyển động phát hiện rung chấn mạnh 28.5 m/s² đột ngột (nghi vấn bị ngã hoặc va đập máy).',
      latitude: _currentDevice!.currentLatitude,
      longitude: _currentDevice!.currentLongitude,
      noiseDecibel: _currentDecibel,
      severity: 'High',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi cảnh báo té ngã / va chạm máy tới Phụ huynh!'),
        backgroundColor: Colors.deepOrange,
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _accelX = 0.0;
          _accelY = 0.0;
          _accelZ = 9.8;
          _accelerometerG = 9.8;
        });
      }
    });
  }

  // Nút SOS Khẩn Cấp từ trẻ
  Future<void> _triggerManualSOS() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text('Kích Hoạt SOS Khẩn Cấp?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tín hiệu báo nguy và vị trí GPS chính xác của bạn sẽ được gửi NGAY LẬP TỨC cho Cha Mẹ!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('GỬI CỨU HỘ NGAY'),
          ),
        ],
      ),
    );

    if (confirm == true && _currentDevice != null) {
      final res = await AlertService().triggerAlert(
        childDeviceId: _currentDevice!.id,
        alertType: 'SOS_MANUAL',
        title: '🆘 BÉ PHÁT TÍN HIỆU SOS KHẨN CẤP!',
        description: 'Bé đã nhấn nút cầu cứu SOS trên màn hình điện thoại. Cần hỗ trợ khẩn cấp!',
        latitude: _currentDevice!.currentLatitude,
        longitude: _currentDevice!.currentLongitude,
        noiseDecibel: _currentDecibel,
        severity: 'Critical',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ĐÃ PHÁT TÍN HIỆU SOS CỨU HỘ THÀNH CÔNG!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Quét / Nhập mã QR Ghép đôi với máy phụ huynh (Chức năng thuyết trình E)
  void _showPairDeviceDialog() {
    final codeCtrl = TextEditingController(text: 'KID-88662');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ghép Đôi Với Máy Cha Mẹ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập mã kết nối hoặc mã QR trên máy của Cha Mẹ:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
              decoration: const InputDecoration(
                hintText: 'KID-XXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await DeviceService().pairDevice(deviceCode: codeCtrl.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message']),
                  backgroundColor: res['success'] ? Colors.green : Colors.red,
                ),
              );
              _loadChildDevice();
            },
            child: const Text('Ghép đôi ngay'),
          ),
        ],
      ),
    );
  }

  void _logoutChildMode() async {
    final passCtrl = TextEditingController();
    bool isChecking = false;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF4F46E5), size: 28),
              SizedBox(width: 10),
              Text('Xác Thực Phụ Huynh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập mật khẩu tài khoản Phụ huynh để mở khóa hoặc thoát khỏi chế độ bảo vệ trẻ em:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu phụ huynh (hoặc admin123)',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  errorText: errorMsg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isChecking ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isChecking
                  ? null
                  : () async {
                      final enteredPass = passCtrl.text.trim();
                      if (enteredPass.isEmpty) {
                        setDialogState(() => errorMsg = 'Vui lòng nhập mật khẩu');
                        return;
                      }

                      setDialogState(() {
                        isChecking = true;
                        errorMsg = null;
                      });

                      final res = await AuthService().verifyParentPassword(
                        parentId: _currentDevice?.parentId,
                        childUserId: _currentDevice?.childUserId,
                        childDeviceId: _currentDevice?.id,
                        password: enteredPass,
                      );

                      if (res['success'] == true) {
                        Navigator.pop(ctx);

                        // Nếu máy đang ở trạng thái khóa từ xa, mở khóa luôn
                        if (_currentDevice != null && _currentDevice!.isLocked) {
                          await DeviceService().toggleLock(_currentDevice!.id, false);
                        }

                        await AuthService().logout();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        setDialogState(() {
                          isChecking = false;
                          errorMsg = res['message'] ?? 'Mật khẩu phụ huynh không chính xác!';
                        });
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: isChecking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Xác nhận thoát'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dev = _currentDevice;
    final remainingMinutes = dev?.remainingScreenTimeMinutes ?? 60;
    final isLocked = (dev?.isLocked ?? false) || (remainingMinutes <= 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLocked
                        ? 'Điện thoại đang bị KHÓA bởi Phụ huynh. Không thể dùng phím Back!'
                        : 'Chế độ trẻ em đang được bảo vệ. Vui lòng bấm biểu tượng ổ khóa ở góc phải để nhập mật khẩu Phụ huynh.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: isLocked ? Colors.red.shade900 : const Color(0xFF1E293B),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: isLocked ? Colors.red.shade900 : const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.red.shade800 : Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : Icons.child_care_rounded,
                  color: isLocked ? Colors.white : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev?.childName ?? 'Bé Huỳnh Gia Nam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    isLocked ? '🔒 Trạng thái: ĐANG BỊ KHÓA' : (dev?.deviceName ?? 'Thiết bị con'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                      color: isLocked ? Colors.amberAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (!isLocked)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.indigo),
                tooltip: 'Ghép đôi QR',
                onPressed: _showPairDeviceDialog,
              ),
            IconButton(
              icon: Icon(
                Icons.lock_person_rounded,
                color: isLocked ? Colors.white : Colors.grey.shade700,
              ),
              tooltip: 'Thoát chế độ trẻ em',
              onPressed: _logoutChildMode,
            ),
          ],
        ),
      body: isLocked
          ? _buildLockedScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Đồng hồ thời gian thực và % pin phần cứng thật của máy
                  _buildLiveDeviceStatusBar(),

                  // Đồng hồ thời gian sử dụng
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Thời gian dùng máy còn lại hôm nay',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 36),
                            const SizedBox(width: 10),
                            Text(
                              '$remainingMinutes',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text(
                              ' phút',
                              style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đã dùng ${dev?.usedScreenTimeMinutes ?? 0} / ${dev?.dailyScreenTimeLimitMinutes ?? 120} phút',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // NÚT SOS KHẨN CẤP ĐỎ RỰC
                  GestureDetector(
                    onTap: _triggerManualSOS,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sos_rounded, color: Colors.white, size: 40),
                          SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NÚT SOS KHẨN CẤP',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Text(
                                  'Chạm 1 lần để báo nguy và gửi GPS ngay',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CẢM BIẾN TIẾNG ỒN & MÔI TRƯỜNG BẠO LỰC (Chức năng thuyết trình D & Tính năng độc quyền)
                  NoiseMeterWidget(
                    decibel: _currentDecibel,
                    isRecording: _isMicActive,
                    onToggleRecording: () => setState(() => _isMicActive = !_isMicActive),
                  ),

                  const SizedBox(height: 12),

                  // Nút test thử nghiệm tính năng tiếng ồn lớn & bạo lực học đường
                  OutlinedButton.icon(
                    onPressed: _simulateHighNoiseBullyingIncident,
                    icon: const Icon(Icons.volume_up_rounded, color: Colors.red),
                    label: const Flexible(
                      child: Text(
                        'Test: Tiếng Ồn Đột Biến > 90dB (Bạo lực học đường)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CẢM BIẾN GIA TỐC RUNG CHẤN THẬT CỦA ĐIỆN THOẠI (Chức năng thuyết trình D)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12),
                      ],
                      border: Border.all(
                        color: _accelerometerG > 22
                            ? Colors.red
                            : (_accelerometerG > 14 ? Colors.orange : Colors.grey.shade200),
                        width: _accelerometerG > 22 ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _accelerometerG > 22 ? Colors.red.shade50 : Colors.orange.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.vibration_rounded,
                                      color: _accelerometerG > 22 ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cảm Biến Gia Tốc Rung Chấn',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Hardware Accelerometer Sensor',
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isRealSensorActive ? Colors.green.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isRealSensorActive ? Colors.green.shade200 : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sensors_rounded,
                                    size: 14,
                                    color: _isRealSensorActive ? Colors.green.shade700 : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isRealSensorActive ? 'SENSOR THẬT' : 'SẴN SÀNG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _isRealSensorActive ? Colors.green.shade700 : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Hiển thị 3 trục gia tốc phần cứng X, Y, Z
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Trục X', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_accelX.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                                    ),
                                    const Text('m/s²', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Trục Y', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_accelY.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                    ),
                                    const Text('m/s²', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Trục Z', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_accelZ.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                                    ),
                                    const Text('m/s²', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Thanh đo tổng lực gia tốc thời gian thực
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng gia tốc: ${_accelerometerG.toStringAsFixed(2)} m/s²',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _accelerometerG > 22
                                  ? '💥 RUNG CHẤN MẠNH!'
                                  : (_accelerometerG > 14 ? '⚡ Chuyển động nhanh' : '✓ Ổn định bình thường'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _accelerometerG > 22
                                    ? Colors.red
                                    : (_accelerometerG > 14 ? Colors.orange.shade800 : Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_accelerometerG / 30.0).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _accelerometerG > 22
                                  ? Colors.red
                                  : (_accelerometerG > 14 ? Colors.orange : Colors.green),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 16, color: Colors.indigo),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lắc hoặc nghiêng điện thoại để thấy gia tốc 3 trục X, Y, Z thay đổi tức thì từ cảm biến thật!',
                                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _simulateFallImpactIncident,
                            icon: const Icon(Icons.flash_on_rounded, size: 18),
                            label: const Text('Test Rung Lắc Té Ngã (Dành cho máy ảo/chấm thi)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DANH SÁCH NHIỆM VỤ RÈN LUYỆN (Tính năng độc quyền 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhiệm Vụ Đổi Thêm Giờ Dùng Máy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('${_quests.length} nhiệm vụ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_quests.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có nhiệm vụ nào được giao')))
                  else
                    ..._quests.map((quest) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: ListTile(
                          title: Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${quest.description}\nThưởng: +${quest.rewardMinutes} phút'),
                          trailing: quest.isCompleted
                              ? const Text('✓ Chờ duyệt', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                              : FilledButton(
                                  onPressed: () async {
                                    await HabitService().completeQuest(quest.id);
                                    _loadChildDevice();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã báo cáo hoàn thành! Chờ cha mẹ duyệt thưởng.')),
                                    );
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                                  child: const Text('Hoàn thành'),
                                ),
                        ),
                      );
                    }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildLiveDeviceStatusBar({bool isDark = false}) {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final min = _currentTime.minute.toString().padLeft(2, '0');
    final sec = _currentTime.second.toString().padLeft(2, '0');
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayName = dayNames[_currentTime.weekday - 1];

    final isCharging = _batteryState == BatteryState.charging;
    final isLowBattery = _currentBatteryLevel <= 20;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white24) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Đồng hồ thời gian thực tế của điện thoại
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_rounded, size: 20, color: isDark ? Colors.white : const Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$hour:$min:$sec',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$dayName, ${_currentTime.day}/${_currentTime.month}/${_currentTime.year}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          // Mức pin thật hiện tại của máy
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '$_currentBatteryLevel%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : (isLowBattery
                                  ? Colors.red
                                  : (isCharging ? Colors.teal : Colors.green.shade700)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isCharging
                            ? Icons.battery_charging_full_rounded
                            : (isLowBattery
                                ? Icons.battery_alert_rounded
                                : (_currentBatteryLevel <= 50 ? Icons.battery_3_bar_rounded : Icons.battery_full_rounded)),
                        size: 22,
                        color: isDark
                            ? Colors.amber
                            : (isLowBattery
                                ? Colors.red
                                : (isCharging ? Colors.teal : Colors.green.shade700)),
                      ),
                    ],
                  ),
                  Text(
                    isCharging ? 'Đang sạc điện thoại ⚡' : 'Pin thiết bị thật',
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLiveDeviceStatusBar(isDark: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.phonelink_lock_rounded, size: 72, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'ĐIỆN THOẠI ĐANG BỊ KHÓA',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đã hết thời gian sử dụng trong ngày hoặc Phụ huynh đã tạm khóa máy từ xa để bé tập trung học bài và nghỉ ngơi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _triggerManualSOS,
              icon: const Icon(Icons.sos_rounded, color: Colors.red),
              label: const Text('GỌI SOS KHẨN CẤP CHO CHA MẸ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _logoutChildMode,
              icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
              label: const Text('Mở Khóa / Thoát Bằng Mật Khẩu Cha Mẹ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Đồng bộ khóa từ xa thời gian thực với máy Cha Mẹ',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
