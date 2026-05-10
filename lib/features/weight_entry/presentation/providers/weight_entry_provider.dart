import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/tables/weight_records.dart';
import '../../../../data/database/tables/photo_metadata.dart';

/// 体重录入状态
class WeightEntryState {
  final double? weight;
  final List<String> selectedPhotos;
  final bool isProcessingOcr;
  final double? recognizedWeight;
  final bool isSaving;
  final String? errorMessage;

  const WeightEntryState({
    this.weight,
    this.selectedPhotos = const [],
    this.isProcessingOcr = false,
    this.recognizedWeight,
    this.isSaving = false,
    this.errorMessage,
  });

  WeightEntryState copyWith({
    double? weight,
    List<String>? selectedPhotos,
    bool? isProcessingOcr,
    double? recognizedWeight,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool clearRecognizedWeight = false,
  }) {
    return WeightEntryState(
      weight: weight ?? this.weight,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      isProcessingOcr: isProcessingOcr ?? this.isProcessingOcr,
      recognizedWeight: clearRecognizedWeight ? null : (recognizedWeight ?? this.recognizedWeight),
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 体重录入 Notifier
class WeightEntryNotifier extends StateNotifier<WeightEntryState> {
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  WeightEntryNotifier(this._ref) : super(const WeightEntryState());

  /// 设置体重
  void setWeight(double weight) {
    state = state.copyWith(weight: weight);
  }

  /// 添加照片
  Future<void> addPhoto(String? path) async {
    if (path == null) return;

    final savedPath = await _savePhotoLocally(path);
    if (savedPath != null) {
      state = state.copyWith(
        selectedPhotos: [...state.selectedPhotos, savedPath],
      );
    }
  }

  /// 从相机拍照
  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return photo?.path;
    } catch (e) {
      state = state.copyWith(errorMessage: '拍照失败: $e');
      return null;
    }
  }

  /// 从相册选择
  Future<String?> pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return photo?.path;
    } catch (e) {
      state = state.copyWith(errorMessage: '选择照片失败: $e');
      return null;
    }
  }

  /// 移除照片
  void removePhoto(int index) {
    if (index >= 0 && index < state.selectedPhotos.length) {
      final newPhotos = List<String>.from(state.selectedPhotos);
      newPhotos.removeAt(index);
      state = state.copyWith(selectedPhotos: newPhotos);
    }
  }

  /// 执行 OCR 识别
  Future<void> performOcr() async {
    if (state.selectedPhotos.isEmpty) {
      state = state.copyWith(errorMessage: '请先选择照片');
      return;
    }

    state = state.copyWith(isProcessingOcr: true, clearError: true);

    try {
      final imagePath = state.selectedPhotos.first;
      final inputImage = InputImage.fromFilePath(imagePath);

      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 从识别结果中提取体重数字
      final weight = _extractWeightFromText(recognizedText);

      if (weight != null) {
        state = state.copyWith(
          isProcessingOcr: false,
          recognizedWeight: weight,
        );
      } else {
        state = state.copyWith(
          isProcessingOcr: false,
          errorMessage: '未能识别出体重数值，请确保照片中体重秤显示清晰',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessingOcr: false,
        errorMessage: 'OCR识别失败: $e',
      );
    }
  }

  /// 从文本中提取体重
  double? _extractWeightFromText(RecognizedText recognizedText) {
    // 匹配数字的正则（支持小数）
    final weightRegex = RegExp(r'(\d+\.?\d*)\s*(kg|g|lb|KG|G|LB)?', caseSensitive: false);

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final match = weightRegex.firstMatch(line.text);
        if (match != null) {
          final value = double.tryParse(match.group(1)!);
          // 体重合理性校验（0.1 ~ 500 kg）
          if (value != null && value > 0.1 && value < 500) {
            return value;
          }
        }
      }
    }

    return null;
  }

  /// 清除 OCR 结果
  void clearOcrResult() {
    state = state.copyWith(clearRecognizedWeight: true);
  }

  /// 保存记录
  Future<bool> saveRecord({
    required double weight,
    required DateTime date,
    String? note,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final db = _ref.read(databaseProvider);

      // 插入体重记录
      final recordId = await db.into(db.weightRecords).insert(
            WeightRecordsCompanion(
              weight: Value(weight),
              date: Value(date),
              note: Value(note),
            ),
          );

      // 保存照片元数据
      for (final photoPath in state.selectedPhotos) {
        await db.into(db.photoMetadata).insert(
              PhotoMetadataCompanion(
                weightRecordId: Value(recordId),
                filePath: Value(photoPath),
              ),
            );
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '保存失败: $e',
      );
      return false;
    }
  }

  /// 将照片保存到应用私有目录
  Future<String?> _savePhotoLocally(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(directory.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final destPath = p.join(photosDir.path, fileName);

      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}

/// 体重录入 Provider
final weightEntryProvider =
    StateNotifierProvider<WeightEntryNotifier, WeightEntryState>((ref) {
  return WeightEntryNotifier(ref);
});
