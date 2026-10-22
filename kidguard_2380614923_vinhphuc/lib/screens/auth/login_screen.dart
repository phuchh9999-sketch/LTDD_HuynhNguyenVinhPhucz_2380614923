import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../child/child_mode_screen.dart';
import 'register_screen.dart';
import 'face_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'Admin');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRoleNavigation(UserModel user) {
    Widget destination;
    final role = user.role.toLowerCase();

    if (role == 'admin') {
      destination = const AdminDashboardScreen();
    } else if (role == 'staff') {
      destination = const StaffDashboardScreen();
    } else if (role == 'child') {
      destination = const ChildModeScreen();
    } else {
      destination = const ParentDashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _onLoginSuccess(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_logged_in_username', user.username);
    final uname = user.username.toLowerCase();
    final bool setupDone = prefs.getBool('biometric_setup_done_$uname') ?? false;

    if (!setupDone && mounted) {
      await _showBiometricSetupSheet(user);
    } else {
      _handleRoleNavigation(user);
    }
  }

  Future<void> _showBiometricSetupSheet(UserModel user) async {
    final uname = user.username.toLowerCase();
    bool enableFace = true;
    bool enableFingerprint = true;

    final result = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kích Hoạt Sinh Trắc Học',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tài khoản: ${user.fullName ?? user.username} (@${user.username})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: const Text(
                    'Bạn có muốn thêm phương thức đăng nhập bằng Vân tay hoặc Khuôn mặt cho tài khoản này không? Bạn có thể chọn 1 hoặc cả 2 phương thức:',
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Face ID
                InkWell(
                  onTap: () {
                    setSheetState(() => enableFace = !enableFace);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: enableFace ? Colors.indigo.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: enableFace ? Colors.indigo.shade400 : Colors.grey.shade300,
                        width: enableFace ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: enableFace ? const Color(0xFF4F46E5) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nhận diện khuôn mặt (Face ID)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Quét và liên kết khuôn mặt camera riêng cho @${user.username}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: enableFace,
                          activeColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) {
                            setSheetState(() => enableFace = val ?? false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Option 2: Fingerprint
                InkWell(
                  onTap: () {
                    setSheetState(() => enableFingerprint = !enableFingerprint);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: enableFingerprint ? const Color(0xFFECFDF5) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: enableFingerprint ? const Color(0xFF10B981) : Colors.grey.shade300,
                        width: enableFingerprint ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: enableFingerprint ? const Color(0xFF10B981) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xác thực vân tay (Fingerprint)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đăng nhập một chạm bằng cảm biến vân tay vật lý',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: enableFingerprint,
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) {
                            setSheetState(() => enableFingerprint = val ?? false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Action Buttons
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx, {
                        'face': enableFace,
                        'fingerprint': enableFingerprint,
                      });
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Lưu & Tiếp Tục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx, {
                      'face': false,
                      'fingerprint': false,
                    });
                  },
                  child: const Text('Để sau (Bỏ qua)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        },
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_setup_done_$uname', true);

    if (result != null) {
      final bool faceSelected = result['face'] == true;
      final bool fpSelected = result['fingerprint'] == true;

      // Xử lý thiết lập vân tay
      if (fpSelected) {
        final bio = BiometricService();
        final canAuth = await bio.canAuthenticate();
        if (canAuth) {
          final authOk = await bio.authenticate(
            reason: 'Chạm cảm biến vân tay để liên kết với tài khoản ${user.username}',
          );
          if (authOk) {
            await prefs.setBool('has_fingerprint_$uname', true);
            if (user.email != null && user.email!.isNotEmpty) {
              await prefs.setBool('has_fingerprint_${user.email!.toLowerCase()}', true);
            }
            // Lưu trực tiếp vào tài khoản trên Server
            await AuthService().registerBiometrics(
              username: user.username,
              enableFingerprint: true,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã liên kết cảm biến vân tay vào tài khoản ${user.fullName ?? user.username}!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } else {
            await prefs.setBool('has_fingerprint_$uname', false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chưa quét được vân tay. Bạn có thể thiết lập lại sau!'),
                  backgroundColor: Colors.amber,
                ),
              );
            }
          }
        } else {
          await prefs.setBool('has_fingerprint_$uname', false);
        }
      } else {
        await prefs.setBool('has_fingerprint_$uname', false);
      }

      // Xử lý thiết lập khuôn mặt (Face ID)
      if (faceSelected && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaceAuthScreen(
              username: user.username,
              isEnrollmentOnly: true,
            ),
          ),
        );
      } else if (!faceSelected) {
        await prefs.setBool('has_face_id_$uname', false);
      }
    }

    if (mounted) {
      _handleRoleNavigation(user);
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().login(
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success && result.requiresOtp) {
      // Yêu cầu số 2: Tên đăng nhập + Mật khẩu + OTP -> Hiển thị hộp thoại nhập mã OTP
      _showOtpDialog(username, result.tempOtpForDemo);
    } else if (result.success && result.user != null) {
      _onLoginSuccess(result.user!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _showOtpDialog(String username, String? demoOtp) {
    final otpController = TextEditingController(text: demoOtp ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.security_rounded, color: Colors.indigo.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Xác thực 2FA OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, size: 20, color: Colors.indigo.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mã OTP 6 số đã được gửi tới hộp thư Gmail của bạn. Vui lòng kiểm tra email hoặc chạm mã bên dưới để điền nhanh:',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (demoOtp != null)
              InkWell(
                onTap: () => otpController.text = demoOtp,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mã OTP gửi từ Server: $demoOtp (Chạm để điền nhanh)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP')),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final verifyRes = await AuthService().verifyOtp(
                username: username,
                otpCode: otp,
              );
              setState(() => _isLoading = false);

              if (!mounted) return;
              if (verifyRes.success && verifyRes.user != null) {
                _onLoginSuccess(verifyRes.user!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(verifyRes.message), backgroundColor: Colors.red),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận OTP'),
          ),
        ],
      ),
    );
  }

  // Chức năng thuyết trình A: Đăng nhập bằng khuôn mặt Face Recognition (Mở Camera thật)
  Future<void> _handleFaceLogin() async {
    final input = _usernameController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (input.isNotEmpty) {
      setState(() => _isLoading = true);
      final status = await AuthService().getBiometricStatus(input);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (status == null || status['status'] != true) {
        // Kiểm tra xem SharedPreferences cục bộ có không
        final uname = input.toLowerCase();
        final hasFaceLocal = prefs.containsKey('enrolled_face_$uname');
        if (!hasFaceLocal) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.person_search_rounded, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Text('Không tìm thấy tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'Không tìm thấy tài khoản tương ứng với "$input" trong hệ thống.\n\nVui lòng kiểm tra lại Tên đăng nhập hoặc Email!',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
              ],
            ),
          );
          return;
        }
      }

      final effectiveUsername = (status?['username'] as String?) ?? input;
      final fullName = (status?['fullName'] as String?) ?? effectiveUsername;
      final hasFace = status?['hasFace'] == true || prefs.containsKey('enrolled_face_${effectiveUsername.toLowerCase()}');
      final faceData = status?['faceData'] as String?;

      if (faceData != null && faceData.isNotEmpty) {
        await prefs.setString('enrolled_face_${effectiveUsername.toLowerCase()}', faceData);
        await prefs.setBool('has_face_id_${effectiveUsername.toLowerCase()}', true);
        await prefs.setString('enrolled_face_${input.toLowerCase()}', faceData);
        await prefs.setBool('has_face_id_${input.toLowerCase()}', true);
      }

      if (!hasFace) {
        if (!mounted) return;
        // Tài khoản chưa lưu Face ID -> Hiện hộp thoại gợi ý đăng ký ngay
        final shouldEnroll = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.face_retouching_off_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Text('Chưa có Face ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Tài khoản "$fullName" (@$effectiveUsername) chưa lưu dữ liệu khuôn mặt trong hệ thống.\n\nBạn có muốn mở camera để quét và liên kết Face ID cho tài khoản này ngay bây giờ không?',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                child: const Text('Quét & Đăng ký ngay'),
              ),
            ],
          ),
        );

        if (shouldEnroll != true || !mounted) return;

        final user = await Navigator.push<UserModel?>(
          context,
          MaterialPageRoute(
            builder: (_) => FaceAuthScreen(username: effectiveUsername),
          ),
        );
        if (user != null && mounted) {
          _handleRoleNavigation(user);
        }
        return;
      }

      // Đã có Face ID -> Mở Camera đối chiếu
      if (!mounted) return;
      final user = await Navigator.push<UserModel?>(
        context,
        MaterialPageRoute(
          builder: (_) => FaceAuthScreen(username: effectiveUsername),
        ),
      );

      if (user != null && mounted) {
        _handleRoleNavigation(user);
      }
      return;
    }

    // Nếu ô tên đăng nhập rỗng -> Chế độ AI 1:N Quét tự động nhận diện tất cả tài khoản
    if (!mounted) return;
    final user = await Navigator.push<UserModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceAuthScreen(username: ''),
      ),
    );

    if (user != null && mounted) {
      _handleRoleNavigation(user);
    }
  }

  // Chức năng thuyết trình E: Đăng nhập Vân tay sinh trắc học
  Future<void> _handleFingerprintLogin() async {
    final input = _usernameController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    String targetUsername = input;
    String targetFullName = input;
    bool isServerEnrolled = false;

    if (input.isNotEmpty) {
      setState(() => _isLoading = true);
      final status = await AuthService().getBiometricStatus(input);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (status == null || status['status'] != true) {
        final uname = input.toLowerCase();
        final hasFpLocal = prefs.getBool('has_fingerprint_$uname') ?? false;
        if (!hasFpLocal && uname != 'admin') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.person_search_rounded, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Text('Không tìm thấy tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'Không tìm thấy tài khoản tương ứng với "$input" trong hệ thống.\n\nVui lòng kiểm tra lại Tên đăng nhập hoặc Email!',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
              ],
            ),
          );
          return;
        }
      }

      targetUsername = (status?['username'] as String?) ?? input;
      targetFullName = (status?['fullName'] as String?) ?? targetUsername;
      isServerEnrolled = status?['hasFingerprint'] == true;
    } else {
      // Ô nhập rỗng -> Ưu tiên tài khoản đăng nhập gần nhất hoặc Admin
      final lastUser = prefs.getString('last_logged_in_username');
      targetUsername = (lastUser != null && lastUser.isNotEmpty) ? lastUser : 'Admin';
      targetFullName = targetUsername == 'Admin' ? 'Quản Trị Viên Hệ Thống' : targetUsername;
      isServerEnrolled = true;
    }

    final targetLower = targetUsername.toLowerCase();
    final hasFingerprint = isServerEnrolled ||
        (prefs.getBool('has_fingerprint_$targetLower') ?? false) ||
        (targetLower == 'admin');

    if (targetLower != 'admin' && !hasFingerprint) {
      if (!mounted) return;
      // Tài khoản chưa lưu vân tay -> Hỏi có muốn kích hoạt & đăng nhập ngay không
      final shouldEnroll = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              const Text('Kích hoạt Vân tay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Tài khoản "$targetFullName" (@$targetUsername) chưa lưu vân tay trong hệ thống.\n\nBạn có muốn chạm cảm biến vân tay để kích hoạt và đăng nhập ngay cho tài khoản này không?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Chạm cảm biến để kích hoạt'),
            ),
          ],
        ),
      );

      if (shouldEnroll != true || !mounted) return;

      final bio = BiometricService();
      final canAuth = await bio.canAuthenticate();
      if (!canAuth) {
        _showNoFingerprintDialog();
        return;
      }

      final authenticated = await bio.authenticate(
        reason: 'Chạm ngón tay vào cảm biến để kích hoạt vân tay cho tài khoản $targetUsername',
      );

      if (authenticated) {
        setState(() => _isLoading = true);
        // Lưu cờ HasFingerprint lên server!
        await AuthService().registerBiometrics(username: targetUsername, enableFingerprint: true);
        await prefs.setBool('has_fingerprint_$targetLower', true);
        if (input.isNotEmpty) {
          await prefs.setBool('has_fingerprint_${input.toLowerCase()}', true);
        }

        final res = await AuthService().biometricLogin(username: targetUsername);
        setState(() => _isLoading = false);

        if (!mounted) return;
        if (res.success && res.user != null) {
          await prefs.setString('last_logged_in_username', targetUsername);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã kích hoạt vân tay & đăng nhập thành công cho ${res.user!.fullName ?? targetUsername}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _handleRoleNavigation(res.user!);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.red),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực vân tay thất bại hoặc bạn đã hủy.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Đã có vân tay được kích hoạt
    final bio = BiometricService();
    final canAuth = await bio.canAuthenticate();

    if (canAuth) {
      final authenticated = await bio.authenticate(
        reason: 'Chạm ngón tay vào cảm biến vân tay để đăng nhập tài khoản $targetFullName (@$targetUsername)',
      );
      if (authenticated) {
        setState(() => _isLoading = true);
        final res = await AuthService().biometricLogin(username: targetUsername);
        setState(() => _isLoading = false);
        if (!mounted) return;
        if (res.success && res.user != null) {
          await prefs.setBool('has_fingerprint_$targetLower', true);
          await prefs.setString('last_logged_in_username', targetUsername);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${res.message} (Đã xác thực cảm biến vân tay phần cứng cho ${res.user!.fullName ?? targetUsername})'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _handleRoleNavigation(res.user!);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.red),
          );
        }
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực vân tay thất bại! Chưa nhận diện được vân tay hoặc bạn đã hủy thao tác.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    _showNoFingerprintDialog();
  }

  Future<void> _openRegisterScreen() async {
    final registeredUser = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (registeredUser != null && registeredUser.isNotEmpty) {
      setState(() {
        _usernameController.text = registeredUser;
        _passwordController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tài khoản "$registeredUser" đã tạo thành công! Hãy nhập mật khẩu để đăng nhập lần đầu.'),
            backgroundColor: const Color(0xFF4F46E5),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showNoFingerprintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded, size: 64, color: Colors.amber),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không Tìm Thấy Cảm Biến Vân Tay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Thiết bị này không có cảm biến vân tay vật lý hoặc bạn chưa đăng ký vân tay trong Cài đặt hệ thống (Settings -> Security -> Fingerprint).\n\nVui lòng cài đặt vân tay trên thiết bị có cảm biến hoặc đăng nhập bằng Tên đăng nhập & Mật khẩu + OTP.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Đã hiểu, quay lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fillAccount(String user, String pass) {
    _usernameController.text = user;
    _passwordController.text = pass;
  }

  void _showConfigServerDialog() {
    final serverController = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cấu hình WebAPI Host'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ WebAPI Backend:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                hintText: 'http://localhost:5271/api/',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Windows: http://localhost:5271/api/\n• Máy ảo Android: http://10.0.2.2:5271/api/',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton(
            onPressed: () async {
              await ApiConfig.setCustomBaseUrl(serverController.text.trim());
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật Host: ${ApiConfig.baseUrl}'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: Colors.indigo),
            tooltip: 'Cấu hình URL API',
            onPressed: _showConfigServerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & Title
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'KidGuard AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hệ thống quản lý điện thoại trẻ em thông minh\nHuỳnh Nguyễn Vĩnh Phúc - MSSV: 2380614923',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Form Đăng nhập
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tên đăng nhập hoặc Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.indigo),
                        hintText: 'Nhập username hoặc email',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.indigo),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: 'Nhập mật khẩu',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Đăng nhập chính (Có OTP)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Đăng Nhập + Xác Thực OTP',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _openRegisterScreen,
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5)),
                        label: const Text(
                          'Đăng Ký Tài Khoản Mới Qua Email',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Các phương thức sinh trắc học (Chức năng thuyết trình A & E)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleFaceLogin,
                      icon: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF4F46E5)),
                      label: const Text('Khuôn mặt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.indigo.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleFingerprintLogin,
                      icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF10B981)),
                      label: const Text('Vân tay'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Danh sách tài khoản mẫu để chấm thi nhanh chóng
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.deepPurple),
                        SizedBox(width: 6),
                        Text(
                          'Tài khoản Quản Trị Hệ Thống duy nhất:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.deepPurple),
                      label: const Text('Admin (tk: Admin • mk: admin123)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.deepPurple.shade50,
                      onPressed: () => _fillAccount('Admin', 'admin123'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '💡 Lưu ý: Hệ thống chỉ lưu 1 tài khoản Admin duy nhất. Bạn có thể nhấn "Đăng ký qua Email" bên dưới để tạo tài khoản mới.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Link Đăng ký tài khoản qua Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: _openRegisterScreen,
                    child: const Text(
                      'Đăng ký qua Email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
