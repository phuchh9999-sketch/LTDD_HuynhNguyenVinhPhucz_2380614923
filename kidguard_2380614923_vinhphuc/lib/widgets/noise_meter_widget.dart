import 'package:flutter/material.dart';

class NoiseMeterWidget extends StatelessWidget {
  final double decibel;
  final bool isRecording;
  final VoidCallback onToggleRecording;

  const NoiseMeterWidget({
    super.key,
    required this.decibel,
    required this.isRecording,
    required this.onToggleRecording,
  });

  Color get _statusColor {
    if (decibel < 60) return const Color(0xFF10B981);
    if (decibel < 80) return Colors.amber.shade600;
    return Colors.redAccent.shade700;
  }

  String get _statusLabel {
    if (decibel < 60) return 'Môi trường an toàn & yên tĩnh';
    if (decibel < 80) return 'Âm thanh bình thường / Trò chuyện';
    return 'CẢNH BÁO: Tiếng ồn lớn / Nguy cơ bắt nạt!';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (decibel / 120.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
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
                        color: _statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.graphic_eq_rounded, color: _statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cảm biến tiếng ồn môi trường',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Microphone Decibel Monitor',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
              IconButton.filledTonal(
                onPressed: onToggleRecording,
                icon: Icon(isRecording ? Icons.mic_rounded : Icons.mic_off_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red.shade100 : Colors.grey.shade200,
                  foregroundColor: isRecording ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    decibel.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                  const Text(
                    'dB (Decibel)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, color: _statusColor, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _statusLabel,
                    style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
