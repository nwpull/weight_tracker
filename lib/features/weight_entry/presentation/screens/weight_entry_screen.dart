import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/weight_entry_provider.dart';
import '../widgets/weight_input_field.dart';
import '../widgets/photo_picker_widget.dart';
import '../widgets/ocr_result_card.dart';

/// 体重录入页面
class WeightEntryScreen extends ConsumerStatefulWidget {
  const WeightEntryScreen({super.key});

  @override
  ConsumerState<WeightEntryScreen> createState() => _WeightEntryScreenState();
}

class _WeightEntryScreenState extends ConsumerState<WeightEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightEntryProvider);
    final notifier = ref.read(weightEntryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录体重'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : _saveRecord,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppDimensions.pagePadding,
          children: [
            // 体重输入
            WeightInputField(
              controller: _weightController,
              onWeightChanged: (value) {
                notifier.setWeight(value);
              },
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // OCR 识别卡片
            OcrResultCard(
              recognizedWeight: state.recognizedWeight,
              isProcessing: state.isProcessingOcr,
              onConfirm: () {
                if (state.recognizedWeight != null) {
                  _weightController.text = state.recognizedWeight!.toStringAsFixed(1);
                  notifier.setWeight(state.recognizedWeight!);
                }
              },
              onRetry: () => notifier.clearOcrResult(),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // 日期选择
            _DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // 照片上传
            PhotoPickerWidget(
              photos: state.selectedPhotos,
              isProcessing: state.isProcessingOcr,
              onPhotoAdded: (path) => notifier.addPhoto(path),
              onPhotoRemoved: (index) => notifier.removePhoto(index),
              onOcrRequested: () => _performOcr(notifier),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // 备注
            _NoteInput(controller: _noteController),

            const SizedBox(height: AppDimensions.spacing32),

            // 保存按钮
            ElevatedButton(
              onPressed: state.isSaving ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存记录'),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _performOcr(WeightEntryNotifier notifier) async {
    await notifier.performOcr();
    // 如果识别成功，自动填充
    final state = ref.read(weightEntryProvider);
    if (state.recognizedWeight != null && mounted) {
      _weightController.text = state.recognizedWeight!.toStringAsFixed(1);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的体重值')),
      );
      return;
    }

    final notifier = ref.read(weightEntryProvider.notifier);
    final success = await notifier.saveRecord(
      weight: weight,
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }
}

/// 日期选择器
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日', 'zh_CN');

    return InkWell(
      onTap: () => _showDatePicker(context),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              dateFormat.format(selectedDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (date != null) {
      onDateSelected(date);
    }
  }
}

/// 备注输入
class _NoteInput extends StatelessWidget {
  final TextEditingController controller;

  const _NoteInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: '备注（可选）',
        hintText: '记录今天的情况...',
        alignLabelWithHint: true,
      ),
    );
  }
}
