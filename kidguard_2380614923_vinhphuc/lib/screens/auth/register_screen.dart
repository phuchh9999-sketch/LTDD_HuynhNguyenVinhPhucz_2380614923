import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childDeviceNameController = TextEditingController();
  String _selectedRole = 'Parent';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _childNameController.dispose();
    _childDeviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ các thông tin')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không đúng định dạng hợp lệ')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu tối thiểu phải từ 6 ký tự')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().register(
      email: email,
      username: username,
      password: password,
      fullName: fullName,
      role: _selectedRole,
      initials: fullName.length > 2 ? fullName.substring(0, 2).toUpperCase() : 'VP',
      childName: _selectedRole == 'Parent' && _childNameController.text.trim().isNotEmpty
          ? _childNameController.text.trim()
          : null,
      childDeviceName: _selectedRole == 'Parent' && _childDeviceNameController.text.trim().isNotEmpty
          ? _childDeviceNameController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message} Đăng nhập để kích hoạt sinh trắc học!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, username);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tạo tài khoản mới qua Email',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tham gia mạng lưới bảo vệ và định vị an toàn cho con trẻ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRole == 'Child' ? 'Họ và tên của bé' : 'Họ và tên',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          _selectedRole == 'Child' ? Icons.child_care_rounded : Icons.badge_outlined,
                          color: Colors.indigo,
                        ),
                        hintText: _selectedRole == 'Child' ? 'Ví dụ: Bé An (8 tuổi)' : 'Ví dụ: Huỳnh Nguyễn Vĩnh Phúc',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _selectedRole == 'Child' ? 'Email của phụ huynh (dùng để liên kết)' : 'Email xác thực',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
                        hintText: _selectedRole == 'Child' ? 'Nhập email của phụ huynh (VD: mail@gmail.com)' : 'name@example.com',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _selectedRole == 'Child' ? 'Tên đăng nhập của bé (Username)' : 'Tên đăng nhập (Username)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.indigo),
                        hintText: _selectedRole == 'Child' ? 'Ví dụ: be_an' : 'Nhập tên đăng nhập',
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
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: 'Tối thiểu 6 ký tự',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Vai trò người dùng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.assignment_ind_outlined, color: Colors.indigo),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Parent', child: Text('Phụ huynh (Parent)')),
                        DropdownMenuItem(value: 'Staff', child: Text('Nhân viên hỗ trợ (Staff)')),
                        DropdownMenuItem(value: 'Child', child: Text('Trẻ em (Child)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),

                    if (_selectedRole == 'Child') ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.family_restroom_rounded, color: Color(0xFF16A34A), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Liên kết tài khoản với Phụ huynh',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14532D)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bé có thể dùng trực tiếp email của phụ huynh để đăng ký. Hệ thống sẽ tự động ghép nối tài khoản của bé với phụ huynh sở hữu email này, giúp ba mẹ quản lý định vị GPS và thời gian sử dụng thiết bị.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedRole == 'Parent') ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.child_care_rounded, color: Color(0xFF4F46E5), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin con trẻ & Thiết bị',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF312E81)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Thiết bị của bé sẽ được tự động tạo và liên kết ngay vào tài khoản phụ huynh để theo dõi định vị & thời gian dùng.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 14),
                            const Text('Tên của bé', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _childNameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.face_outlined, color: Color(0xFF4F46E5)),
                                hintText: 'Ví dụ: Bé An (8 tuổi)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Tên điện thoại của bé', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _childDeviceNameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_android_outlined, color: Color(0xFF4F46E5)),
                                hintText: 'Ví dụ: Samsung Galaxy A54',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC7D2FE))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: FilledButton.styleFrom(
                          backgroundColor: _selectedRole == 'Child' ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _selectedRole == 'Child' ? 'Đăng Ký Tài Khoản Cho Trẻ' : 'Đăng Ký Tài Khoản',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
