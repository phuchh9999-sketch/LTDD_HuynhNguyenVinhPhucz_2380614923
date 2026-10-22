import 'package:flutter/material.dart';

class QrDisplayDialog extends StatelessWidget {
  final String deviceCode;
  final String deviceName;

  const QrDisplayDialog({
    super.key,
    required this.deviceCode,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2_rounded, size: 36, color: Colors.indigo.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mã QR Ghép Đôi Thiết Bị',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Dùng máy của bé quét mã này hoặc nhập mã số bên dưới để kết nối giám sát.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Khung hiển thị mô phỏng mã QR đồ họa sắc nét
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildQrMatrixMock(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deviceCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thiết bị: $deviceName',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrMatrixMock() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 49,
            itemBuilder: (context, index) {
              // Create realistic QR corner finder patterns
              final row = index ~/ 7;
              final col = index % 7;
              final isTopLeft = (row < 3 && col < 3);
              final isTopRight = (row < 3 && col > 3);
              final isBottomLeft = (row > 3 && col < 3);

              if (isTopLeft || isTopRight || isBottomLeft) {
                final isBorder = (row == 0 || row == 2 || col == 0 || col == 2) && isTopLeft ||
                    (row == 0 || row == 2 || col == 4 || col == 6) && isTopRight ||
                    (row == 4 || row == 6 || col == 0 || col == 2) && isBottomLeft;
                final isCenter = (row == 1 && col == 1) || (row == 1 && col == 5) || (row == 5 && col == 1);
                return Container(
                  color: (isBorder || isCenter) ? Colors.indigo.shade900 : Colors.white,
                );
              }
              // Random dots based on hash of deviceCode
              final isFilled = (index * 13 + deviceCode.hashCode) % 3 != 0;
              return Container(
                color: isFilled ? Colors.indigo.shade900 : Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}
