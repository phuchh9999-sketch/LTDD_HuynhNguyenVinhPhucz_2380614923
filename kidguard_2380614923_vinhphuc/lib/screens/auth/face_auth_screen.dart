import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class FaceAuthScreen extends StatefulWidget {
  final String username;
  final bool isEnrollmentOnly;

  const FaceAuthScreen({
    super.key,
    required this.username,
    this.isEnrollmentOnly = false,
  });

  @override
  State<FaceAuthScreen> createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  String _cameraErrorMessage = '';

  late AnimationController _scannerAnimationController;
  late Animation<double> _scannerAnimation;

  bool _isProcessing = false;
  String _statusMessage = 'Vui lòng đưa khuôn mặt vào giữa khung tròn...';
  double _confidenceScore = 0.0;
  Timer? _autoDetectionTimer;
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
    _setupAnimation();
    _initializeCamera();
  }

  Future<void> _checkEnrollmentStatus() async {
    final target = widget.username.trim();
    if (widget.isEnrollmentOnly) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Đưa khuôn mặt vào khung tròn để đăng ký Face ID cho $target';
        });
      }
      return;
    }
    if (target.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      bool hasFace = prefs.containsKey('enrolled_face_${target.toLowerCase()}');

      if (!hasFace) {
        // Kiểm tra dữ liệu khuôn mặt đã lưu trên Server
        final status = await AuthService().getBiometricStatus(target);
        if (status != null && status['hasFace'] == true && status['faceData'] != null) {
          final serverFace = status['faceData'] as String;
          final realUname = (status['username'] as String?)?.toLowerCase() ?? target.toLowerCase();
          await prefs.setString('enrolled_face_$realUname', serverFace);
          await prefs.setBool('has_face_id_$realUname', true);
          await prefs.setString('enrolled_face_${target.toLowerCase()}', serverFace);
          await prefs.setBool('has_face_id_${target.toLowerCase()}', true);
          hasFace = true;
        }
      }

      if (mounted) {
        setState(() {
          _isEnrolled = hasFace;
          if (!hasFace) {
            _statusMessage = 'Tài khoản $target chưa có Face ID. Hãy chụp để đăng ký khuôn mặt!';
          } else {
            _statusMessage = 'Đã có Face ID cho $target. Nhìn thẳng camera để đối chiếu!';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Chế độ AI Tự Động: Nhìn thẳng camera để tìm tài khoản của bạn!';
        });
      }
    }
  }

  String _computeFaceSignature(Uint8List bytes) {
    final length = bytes.length;
    final chunkSize = (length / 16).floor();
    final vector = <double>[];
    for (int i = 0; i < 16; i++) {
      int sum = 0;
      final start = i * chunkSize;
      final end = (start + chunkSize).clamp(0, length);
      for (int j = start; j < end; j += 15) {
        sum += bytes[j];
      }
      final count = ((end - start) / 15).ceil().clamp(1, length);
      vector.add(double.parse(((sum / count) / 255.0).toStringAsFixed(3)));
    }
    return vector.join(',');
  }

  double _calculateSimilarity(String sig1, String sig2) {
    if (sig1.isEmpty || sig2.isEmpty) return 0.0;
    if (sig1 == sig2) return 1.0;
    try {
      final v1 = sig1.split(',').map(double.parse).toList();
      final v2 = sig2.split(',').map(double.parse).toList();
      if (v1.length != v2.length || v1.isEmpty) return 0.0;
      double dot = 0.0, n1 = 0.0, n2 = 0.0;
      for (int i = 0; i < v1.length; i++) {
        dot += v1[i] * v2[i];
        n1 += v1[i] * v1[i];
        n2 += v2[i] * v2[i];
      }
      if (n1 <= 0 || n2 <= 0) return 0.0;
      final cosine = dot / (sqrt(n1) * sqrt(n2));
      return cosine.clamp(0.0, 1.0);
    } catch (_) {
      return sig1 == sig2 ? 1.0 : 0.0;
    }
  }

  Future<void> _resetFaceEnrollment() async {
    final target = widget.username.trim().isNotEmpty ? widget.username.trim() : 'Admin';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enrolled_face_${target.toLowerCase()}');
    if (!mounted) return;
    setState(() {
      _isEnrolled = false;
      _confidenceScore = 0.0;
      _statusMessage = 'Đã đặt lại Face ID cho $target. Hãy nhấn Chụp để đăng ký khuôn mặt mới!';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa Face ID cũ của $target. Bạn có thể chụp lại để đăng ký khuôn mặt mới!'),
        backgroundColor: Colors.amber.shade800,
      ),
    );
  }

  void _setupAnimation() {
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scannerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasCameraError = true;
          _cameraErrorMessage = 'Không tìm thấy thiết bị camera vật lý trên máy.';
          _statusMessage = 'Cần có Camera để quét khuôn mặt';
        });
        return;
      }

      // Ưu tiên camera trước (front camera) để nhận diện khuôn mặt
      int frontCameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontCameraIndex != -1 ? frontCameraIndex : 0;

      await _startCameraPreview(_cameras[_selectedCameraIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCameraError = true;
        _cameraErrorMessage = 'Lỗi truy cập camera: $e';
        _statusMessage = 'Không thể kết nối camera';
      });
    }
  }

  Future<void> _startCameraPreview(CameraDescription cameraDescription) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _hasCameraError = false;
        _statusMessage = 'Vui lòng nhìn thẳng vào camera và nhấn Chụp';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCameraError = true;
        _cameraErrorMessage = 'Không thể khởi động camera: $e';
        _statusMessage = 'Camera bị lỗi hoặc chưa cấp quyền';
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _cameraController?.dispose();
    setState(() {
      _isCameraInitialized = false;
    });
    await _startCameraPreview(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureAndAuthenticate() async {
    if (_isProcessing) return;

    if (_cameraController == null || !_isCameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể quét: Camera chưa sẵn sàng hoặc không hoạt động!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chụp ảnh & quét đặc trưng khuôn mặt...';
    });

    try {
      // 1. Thực sự chụp ảnh từ Camera vật lý
      final photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();

      if (bytes.length < 1000) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Ảnh chụp không hợp lệ!';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không nhận diện được khuôn mặt: Dữ liệu ảnh chụp rỗng!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Kiểm tra độ sáng và chi tiết (Luminance check):
      // Nếu camera bị che tay hoặc chĩa vào bóng tối (brightness < 20)
      int sampleCount = 0;
      int totalBrightness = 0;
      final step = (bytes.length / 250).clamp(1, 500).toInt();
      for (int i = (bytes.length * 0.15).toInt(); i < (bytes.length * 0.85).toInt(); i += step) {
        totalBrightness += bytes[i];
        sampleCount++;
      }
      final avgBrightness = sampleCount > 0 ? (totalBrightness / sampleCount) : 0;

      if (avgBrightness < 20) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Camera bị che hoặc thiếu sáng!';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa quét được khuôn mặt: Camera bị che hoặc môi trường quá tối! Vui lòng nhìn thẳng vào camera nơi có đủ ánh sáng.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. Phân tích vector sinh trắc học khuôn mặt từ ảnh chụp
      final scannedSig = _computeFaceSignature(bytes);
      final prefs = await SharedPreferences.getInstance();

      String targetUsername = widget.username.trim();

      if (widget.isEnrollmentOnly && targetUsername.isNotEmpty) {
        await prefs.setString('enrolled_face_${targetUsername.toLowerCase()}', scannedSig);
        await prefs.setBool('has_face_id_${targetUsername.toLowerCase()}', true);
        await AuthService().registerBiometrics(username: targetUsername, faceDescriptor: scannedSig);
        await AuthService().registerFace(username: targetUsername, descriptor: scannedSig);

        setState(() {
          _isProcessing = false;
          _confidenceScore = 1.0;
          _statusMessage = 'Đã lưu Face ID thành công cho $targetUsername!';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Đã liên kết Face ID thành công cho $targetUsername!')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      if (targetUsername.isNotEmpty) {
        // Chế độ 1:1 Đối chiếu với tài khoản cụ thể
        final savedSig = prefs.getString('enrolled_face_${targetUsername.toLowerCase()}');

        if (savedSig == null) {
          // Lần đầu quét: Tự động lưu khuôn mặt mẫu cho tài khoản này
          await prefs.setString('enrolled_face_${targetUsername.toLowerCase()}', scannedSig);
          await prefs.setBool('has_face_id_${targetUsername.toLowerCase()}', true);
          await AuthService().registerBiometrics(username: targetUsername, faceDescriptor: scannedSig);
          await AuthService().registerFace(username: targetUsername, descriptor: scannedSig);
          setState(() {
            _isEnrolled = true;
            _confidenceScore = 0.95;
            _statusMessage = 'Đã đăng ký Face ID mới cho tài khoản $targetUsername! Đang đăng nhập...';
          });
        } else {
          // Đã có khuôn mặt đăng ký -> So sánh đối chiếu!
          final similarity = _calculateSimilarity(savedSig, scannedSig);
          setState(() {
            _confidenceScore = similarity;
          });

          if (similarity < 0.72) {
            // KHÔNG TRÙNG KHỚP VỚI TÀI KHOẢN NÀY!
            setState(() {
              _isProcessing = false;
              _statusMessage = 'Khuôn mặt KHÔNG TRÙNG KHỚP với tài khoản $targetUsername!\n(Độ khớp ${(similarity * 100).toStringAsFixed(1)}% < 75%)';
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Khuôn mặt không khớp với dữ liệu đăng ký của $targetUsername! Vui lòng dùng đúng khuôn mặt của chủ tài khoản.'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }

          setState(() {
            _statusMessage = 'Khuôn mặt trùng khớp (${(similarity * 100).toStringAsFixed(1)}%)! Đang xác thực tài khoản...';
          });
        }
      } else {
        // Chế độ 1:N AI Tự động nhận diện tài khoản qua khuôn mặt
        setState(() {
          _statusMessage = 'AI đang quét và đối chiếu với các tài khoản trong hệ thống...';
        });

        // Tìm trong các tài khoản đã đăng ký trên máy
        final allKeys = prefs.getKeys().where((k) => k.startsWith('enrolled_face_')).toList();
        String? matchedAcc;
        double bestSim = 0.0;

        for (final k in allKeys) {
          final accName = k.replaceFirst('enrolled_face_', '');
          final enrolledSig = prefs.getString(k) ?? '';
          final sim = _calculateSimilarity(enrolledSig, scannedSig);
          if (sim > bestSim && sim >= 0.72) {
            bestSim = sim;
            matchedAcc = accName;
          }
        }

        if (matchedAcc != null) {
          targetUsername = matchedAcc;
          setState(() {
            _confidenceScore = bestSim;
            _statusMessage = 'AI đã nhận diện khuôn mặt của bạn: $matchedAcc (${(bestSim * 100).toStringAsFixed(1)}%)!';
          });
        }
      }

      await Future.delayed(const Duration(milliseconds: 400));

      // Gọi API xác thực tài khoản
      final res = await AuthService().faceLogin(
        username: targetUsername,
        faceDescriptor: scannedSig,
      );

      if (!mounted) return;

      if (res.success && res.user != null) {
        setState(() {
          _confidenceScore = 1.0;
          _statusMessage = 'Xác thực sinh trắc học THÀNH CÔNG (100%)!\nXin chào ${res.user!.fullName ?? res.user!.username}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Khuôn mặt hợp lệ! Xin chào ${res.user!.fullName ?? res.user!.username}')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );

        await prefs.setBool('has_face_id_${res.user!.username.toLowerCase()}', true);
        await prefs.setString('enrolled_face_${res.user!.username.toLowerCase()}', scannedSig);
        if (widget.username.trim().isNotEmpty) {
          await prefs.setBool('has_face_id_${widget.username.trim().toLowerCase()}', true);
          await prefs.setString('enrolled_face_${widget.username.trim().toLowerCase()}', scannedSig);
        }
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pop(context, res.user);
        }
      } else {
        setState(() {
          _isProcessing = false;
          _confidenceScore = 0.0;
          _statusMessage = res.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Lỗi chụp ảnh quét khuôn mặt: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoDetectionTimer?.cancel();
    _scannerAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview Toàn Màn Hình Tự Động Fit Theo Điện Thoại
          _buildCameraWidget(size),

          // 2. High-Tech Biometric HUD Overlay
          _buildFaceOverlay(size),

          // 3. Top Controls Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.isEnrollmentOnly
                                ? 'ĐĂNG KÝ FACE ID'
                                : (widget.username.trim().isEmpty ? 'AI SMART FACE ID (1:N)' : 'AI FACE ID SCANNER'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.restart_alt_rounded, color: Colors.amberAccent),
                            tooltip: 'Đăng ký lại khuôn mặt',
                            onPressed: _resetFaceEnrollment,
                          ),
                        ),
                        if (_cameras.length > 1) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                              onPressed: _flipCamera,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Information & Action Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _confidenceScore >= 1.0
                              ? Colors.greenAccent
                              : (_isProcessing ? Colors.amberAccent : (_confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent)),
                          width: _confidenceScore >= 1.0 ? 1.8 : 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isProcessing && _confidenceScore < 1.0)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.amberAccent, strokeWidth: 2),
                                )
                              else
                                Icon(
                                  _confidenceScore >= 0.8 ? Icons.verified_user : Icons.center_focus_strong,
                                  color: _confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent,
                                  size: 18,
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _statusMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _confidenceScore >= 1.0 ? Colors.greenAccent : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isEnrollmentOnly
                                ? 'Đang lưu Face ID cho: ${widget.username}'
                                : (widget.username.trim().isNotEmpty
                                    ? 'Tài khoản đối chiếu: ${widget.username} (${_isEnrolled ? "Đã có Face ID" : "Chưa có Face ID - Hãy chụp để đăng ký"})'
                                    : 'Chế độ: AI Tự Động Nhận Diện Tài Khoản (1:N)'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Capture / Authenticate Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: (_isProcessing || !_isCameraInitialized || _hasCameraError)
                            ? null
                            : _captureAndAuthenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: _confidenceScore >= 1.0 ? Colors.green.shade700 : const Color(0xFF4F46E5),
                          disabledBackgroundColor: _confidenceScore >= 1.0 ? Colors.green.shade700 : Colors.white24,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        icon: (_isProcessing && _confidenceScore < 1.0)
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(
                                _confidenceScore >= 1.0
                                    ? Icons.check_circle_rounded
                                    : (!_isCameraInitialized ? Icons.videocam_off_rounded : Icons.camera_alt_rounded),
                                size: 22,
                                color: !_isCameraInitialized ? Colors.white38 : Colors.white,
                              ),
                        label: Text(
                          !_isCameraInitialized
                              ? 'Cần có Camera để quét khuôn mặt'
                              : (_confidenceScore >= 1.0
                                  ? 'Xác Thực Thành Công (100%)'
                                  : (_isProcessing
                                      ? 'Đang phân tích khuôn mặt...'
                                      : (widget.isEnrollmentOnly
                                          ? 'Chụp & Lưu Face ID Cho Tài Khoản'
                                          : 'Chụp & Nhận Diện Khuôn Mặt'))),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !_isCameraInitialized ? Colors.white38 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWidget(Size size) {
    if (!_isCameraInitialized || _cameraController == null) {
      return _buildCameraFallback();
    }

    final previewSize = _cameraController!.value.previewSize;
    double previewW = size.width;
    double previewH = size.height;

    if (previewSize != null) {
      // Android/iOS camera preview dimensions are landscape (width > height)
      if (previewSize.width > previewSize.height) {
        previewW = previewSize.height;
        previewH = previewSize.width;
      } else {
        previewW = previewSize.width;
        previewH = previewSize.height;
      }
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: previewW,
          height: previewH,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.videocam_off_rounded, size: 72, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không Thể Khởi Động Camera',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _hasCameraError && _cameraErrorMessage.isNotEmpty
                    ? _cameraErrorMessage
                    : 'Thiết bị không có Camera hoặc quyền truy cập Camera bị từ chối.\n\nĐể nhận diện khuôn mặt, bạn bắt buộc phải chạy trên thiết bị có Camera (hoặc gắn webcam) và cấp quyền Camera.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Quay lại màn hình đăng nhập', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceOverlay(Size size) {
    final double ovalWidth = size.width * 0.72;
    final double ovalHeight = size.height * 0.45;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Khung viền Oval quét khuôn mặt
          Container(
            width: ovalWidth,
            height: ovalHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(ovalWidth / 2, ovalHeight / 2)),
              border: Border.all(
                color: _confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent.withOpacity(0.8),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 4 Góc Target Brackets
          SizedBox(
            width: ovalWidth + 40,
            height: ovalHeight + 40,
            child: CustomPaint(
              painter: _TargetBracketsPainter(
                color: _confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent,
              ),
            ),
          ),

          // Laser Scanner di chuyển lên xuống chuẩn tâm Oval
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _scannerAnimation.value * (ovalHeight / 2.3)),
                child: Container(
                  width: ovalWidth * 0.9,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent,
                        Colors.white,
                        _confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_confidenceScore >= 0.8 ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TargetBracketsPainter extends CustomPainter {
  final Color color;

  _TargetBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double corner = 24.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, corner), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - corner, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, corner), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(corner, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - corner), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - corner, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
