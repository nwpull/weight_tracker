import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// OCR 识别结果卡片
class OcrResultCard extends StatelessWidget {
  final double? recognizedWeight;
  final bool isProcessing;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const OcrResultCard({
    super.key,
    this.recognizedWeight,
    this.isProcessing = false,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProcessing && recognizedWeight == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: recognizedWeight != null
            ? AppColors.success.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: recognizedWeight != null
              ? AppColors.success.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: isProcessing
          ? _buildProcessingState(context)
          : _buildResultState(context),
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Text(
          '正在识别体重...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildResultState(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '识别成功',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '识别到体重: ${recognizedWeight!.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.success,
          ),
          child: const Text('使用'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text('重试'),
        ),
      ],
    );
  }
}
