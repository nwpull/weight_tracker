import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// 目标进度环形图
class GoalProgressRing extends StatelessWidget {
  final double currentWeight;
  final double targetWeight;
  final double startWeight;
  final double size;
  final double strokeWidth;

  const GoalProgressRing({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.startWeight,
    this.size = 200,
    this.strokeWidth = 16,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景环
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              color: AppColors.textHint.withOpacity(0.1),
              strokeWidth: strokeWidth,
            ),
          ),

          // 进度环
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              color: _getProgressColor(progress),
              strokeWidth: strokeWidth,
            ),
          ),

          // 中心内容
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progress),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '完成进度',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentWeight.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (startWeight == targetWeight) return 1.0;

    final totalToLose = startWeight - targetWeight;
    final lost = startWeight - currentWeight;

    if (totalToLose == 0) return 1.0;

    final progress = lost / totalToLose;
    return progress.clamp(0.0, 1.0);
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppColors.success;
    if (progress >= 0.7) return AppColors.primary;
    if (progress >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
}

/// 环形绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2; // 从顶部开始
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
