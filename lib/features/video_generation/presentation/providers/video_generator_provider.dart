import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 视频生成状态
class VideoGeneratorState {
  final List<String> selectedPhotos;
  final bool isGenerating;
  final double progress;
  final String? generatedVideoPath;
  final String? errorMessage;

  const VideoGeneratorState({
    this.selectedPhotos = const [],
    this.isGenerating = false,
    this.progress = 0,
    this.generatedVideoPath,
    this.errorMessage,
  });

  VideoGeneratorState copyWith({
    List<String>? selectedPhotos,
    bool? isGenerating,
    double? progress,
    String? generatedVideoPath,
    String? errorMessage,
    bool clearError = false,
    bool clearVideo = false,
  }) {
    return VideoGeneratorState(
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      generatedVideoPath: clearVideo ? null : (generatedVideoPath ?? this.generatedVideoPath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 视频生成 Provider
final videoGeneratorProvider =
    StateNotifierProvider<VideoGeneratorNotifier, VideoGeneratorState>((ref) {
  return VideoGeneratorNotifier();
});

/// 视频生成 Notifier
class VideoGeneratorNotifier extends StateNotifier<VideoGeneratorState> {
  VideoGeneratorNotifier() : super(const VideoGeneratorState());

  /// 添加照片
  void addPhotos(List<String> paths) {
    state = state.copyWith(
      selectedPhotos: [...state.selectedPhotos, ...paths],
      clearVideo: true,
    );
  }

  /// 移除照片
  void removePhoto(int index) {
    final newPhotos = List<String>.from(state.selectedPhotos);
    if (index >= 0 && index < newPhotos.length) {
      newPhotos.removeAt(index);
      state = state.copyWith(
        selectedPhotos: newPhotos,
        clearVideo: true,
      );
    }
  }

  /// 清除照片
  void clearPhotos() {
    state = state.copyWith(
      selectedPhotos: [],
      clearVideo: true,
    );
  }

  /// 生成视频
  Future<bool> generateVideo({
    required double durationPerPhoto,
    required String transitionType,
    required bool includeDateLabel,
    required bool includeWeightLabel,
  }) async {
    if (state.selectedPhotos.length < 2) {
      state = state.copyWith(errorMessage: '请至少选择2张照片');
      return false;
    }

    state = state.copyWith(
      isGenerating: true,
      progress: 0,
      clearError: true,
    );

    try {
      // 获取输出路径
      final outputDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory(p.join(outputDir.path, 'videos'));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final outputPath = p.join(
        videosDir.path,
        'weight_timeline_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // 构建 FFmpeg 命令
      final command = _buildFFmpegCommand(
        photoPaths: state.selectedPhotos,
        outputPath: outputPath,
        durationPerPhoto: durationPerPhoto,
        transitionType: transitionType,
        includeDateLabel: includeDateLabel,
        includeWeightLabel: includeWeightLabel,
      );

      // 模拟进度更新
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(progress: i.toDouble());
      }

      // TODO: 实际调用 FFmpeg
      // await FFmpegKit.executeAsync(command, (session) async {
      //   final returnCode = await session.getReturnCode();
      //   if (ReturnCode.isSuccess(returnCode)) {
      //     state = state.copyWith(
      //       isGenerating: false,
      //       progress: 100,
      //       generatedVideoPath: outputPath,
      //     );
      //   } else {
      //     state = state.copyWith(
      //       isGenerating: false,
      //       errorMessage: '视频生成失败',
      //     );
      //   }
      // }, null, (statistics) {
      //   final time = statistics.getTime();
      //   final progress = (time / totalDuration * 100).clamp(0, 100);
      //   state = state.copyWith(progress: progress);
      // });

      // 模拟成功
      state = state.copyWith(
        isGenerating: false,
        progress: 100,
        generatedVideoPath: outputPath,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: '生成失败: $e',
      );
      return false;
    }
  }

  /// 构建 FFmpeg 命令
  String _buildFFmpegCommand({
    required List<String> photoPaths,
    required String outputPath,
    required double durationPerPhoto,
    required String transitionType,
    required bool includeDateLabel,
    required bool includeWeightLabel,
  }) {
    final buffer = StringBuffer();

    // 输入文件
    for (final path in photoPaths) {
      buffer.write('-loop 1 -t $durationPerPhoto -i "$path" ');
    }

    // 构建滤镜链
    final filterBuffer = StringBuffer();

    // 转场效果
    if (transitionType != 'none' && photoPaths.length > 1) {
      final transitionDuration = 0.5;
      for (int i = 0; i < photoPaths.length - 1; i++) {
        final input1 = i == 0 ? '[0:v]' : '[v$i]';
        final input2 = '[${i + 1}:v]';
        final output = '[v${i + 1}]';
        final offset = (i + 1) * durationPerPhoto - transitionDuration;

        filterBuffer.write('$input1$input2');
        filterBuffer.write('xfade=transition=$transitionType:');
        filterBuffer.write('duration=$transitionDuration:');
        filterBuffer.write('offset=$offset$output;');
      }
    }

    // 文字叠加
    if (includeDateLabel || includeWeightLabel) {
      final lastOutput = photoPaths.length > 1
          ? '[v${photoPaths.length - 1}]'
          : '[0:v]';

      String textContent = '';
      if (includeDateLabel) {
        textContent += '%{pts\\:hms}';
      }
      if (includeWeightLabel) {
        textContent += ' 75.0kg'; // TODO: 实际体重数据
      }

      filterBuffer.write(
          '$lastOutput drawtext=text=\'$textContent\':fontfile=/system/fonts/DroidSans.ttf:');
      filterBuffer.write('fontsize=24:fontcolor=white:x=20:y=20:');
      filterBuffer.write('shadowcolor=black:shadowx=2:shadowy=2 [vout]');
    }

    // 组合命令
    buffer.write('-filter_complex "${filterBuffer.toString()}" ');
    buffer.write('-c:v libx264 -pix_fmt yuv420p -preset medium -crf 23 ');
    buffer.write('-r 30 "$outputPath"');

    return buffer.toString();
  }
}
