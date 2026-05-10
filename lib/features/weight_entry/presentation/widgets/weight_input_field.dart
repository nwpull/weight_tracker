import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// 体重输入字段
class WeightInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<double>? onWeightChanged;
  final String? label;
  final String? hint;

  const WeightInputField({
    super.key,
    required this.controller,
    this.onWeightChanged,
    this.label,
    this.hint,
  });

  @override
  State<WeightInputField> createState() => _WeightInputFieldState();
}

class _WeightInputFieldState extends State<WeightInputField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label ?? '体重',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint ?? '0.0',
                    hintStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHint.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final weight = double.tryParse(value);
                    if (weight != null && widget.onWeightChanged != null) {
                      widget.onWeightChanged!(weight);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          // 快捷按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickWeightButton(
                label: '-0.5',
                onTap: () => _adjustWeight(-0.5),
              ),
              _QuickWeightButton(
                label: '-0.1',
                onTap: () => _adjustWeight(-0.1),
              ),
              _QuickWeightButton(
                label: '+0.1',
                onTap: () => _adjustWeight(0.1),
              ),
              _QuickWeightButton(
                label: '+0.5',
                onTap: () => _adjustWeight(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _adjustWeight(double delta) {
    final currentValue = double.tryParse(widget.controller.text) ?? 0;
    final newValue = (currentValue + delta).clamp(0.1, 500.0);
    widget.controller.text = newValue.toStringAsFixed(1);
    if (widget.onWeightChanged != null) {
      widget.onWeightChanged!(newValue);
    }
  }
}

/// 快捷体重调整按钮
class _QuickWeightButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickWeightButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing8,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
