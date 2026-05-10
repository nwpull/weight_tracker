import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/video_generator_provider.dart';

/// 视频生成页面
class VideoGeneratorScreen extends ConsumerStatefulWidget {
  const VideoGeneratorScreen({super.key});

  @override
  ConsumerState<VideoGeneratorScreen> createState() => _VideoGeneratorScreenState();
}

class _VideoGeneratorScreenState extends ConsumerState<VideoGeneratorScreen> {
  double _durationPerPhoto = 3.0;
  String _transitionType = 'fade';
  bool _includeDateLabel = true;
  bool _includeWeightLabel = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoGeneratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生成对比视频'),
        actions: [
          if (state.generatedVideoPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareVideo(state.generatedVideoPath!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览区域
            _PreviewArea(
              isGenerating: state.isGenerating,
              progress: state.progress,
              videoPath: state.generatedVideoPath,
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // 照片选择
            _PhotoSelection(
              selectedCount: state.selectedPhotos.length,
              onAddPhotos: () => _showPhotoPicker(),
              onClear: () => ref.read(videoGeneratorProvider.notifier).clearPhotos(),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // 设置选项
            _VideoSettings(
              durationPerPhoto: _durationPerPhoto,
              transitionType: _transitionType,
              includeDateLabel: _includeDateLabel,
              includeWeightLabel: _includeWeightLabel,
              onDurationChanged: (value) {
                setState(() => _durationPerPhoto = value);
              },
              onTransitionChanged: (value) {
                setState(() => _transitionType = value);
              },
              onDateLabelChanged: (value) {
                setState(() => _includeDateLabel = value);
              },
              onWeightLabelChanged: (value) {
                setState(() => _includeWeightLabel = value);
              },
            ),

            const SizedBox(height: AppDimensions.spacing32),

            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isGenerating || state.selectedPhotos.isEmpty
                    ? null
                    : _generateVideo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('生成中... ${state.progress.toStringAsFixed(0)}%'),
                        ],
                      )
                    : const Text('生成视频'),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showPhotoPicker() {
    // TODO: 显示照片选择器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先在照片时间线页面选择照片')),
    );
  }

  Future<void> _generateVideo() async {
    final success = await ref.read(videoGeneratorProvider.notifier).generateVideo(
          durationPerPhoto: _durationPerPhoto,
          transitionType: _transitionType,
          includeDateLabel: _includeDateLabel,
          includeWeightLabel: _includeWeightLabel,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频生成成功！')),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频生成失败，请重试')),
      );
    }
  }

  void _shareVideo(String path) {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }
}

/// 预览区域
class _PreviewArea extends StatelessWidget {
  final bool isGenerating;
  final double progress;
  final String? videoPath;

  const _PreviewArea({
    required this.isGenerating,
    required this.progress,
    this.videoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Center(
        child: isGenerating
            ? _buildGeneratingState(context)
            : videoPath != null
                ? _buildVideoPreview(context, videoPath!)
                : _buildEmptyState(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.movie_creation_outlined,
          size: 48,
          color: AppColors.textHint.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          '选择照片后生成视频',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 6,
            backgroundColor: AppColors.textHint.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '正在生成视频...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview(BuildContext context, String path) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          '视频已生成',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
              ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 播放视频
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('预览'),
        ),
      ],
    );
  }
}

/// 照片选择
class _PhotoSelection extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAddPhotos;
  final VoidCallback onClear;

  const _PhotoSelection({
    required this.selectedCount,
    required this.onAddPhotos,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$selectedCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已选择照片',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  selectedCount > 0
                      ? '$selectedCount 张照片'
                      : '请选择至少2张照片',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (selectedCount > 0)
            TextButton(
              onPressed: onClear,
              child: const Text('清除'),
            ),
          OutlinedButton.icon(
            onPressed: onAddPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('选择'),
          ),
        ],
      ),
    );
  }
}

/// 视频设置
class _VideoSettings extends StatelessWidget {
  final double durationPerPhoto;
  final String transitionType;
  final bool includeDateLabel;
  final bool includeWeightLabel;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<String> onTransitionChanged;
  final ValueChanged<bool> onDateLabelChanged;
  final ValueChanged<bool> onWeightLabelChanged;

  const _VideoSettings({
    required this.durationPerPhoto,
    required this.transitionType,
    required this.includeDateLabel,
    required this.includeWeightLabel,
    required this.onDurationChanged,
    required this.onTransitionChanged,
    required this.onDateLabelChanged,
    required this.onWeightLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '视频设置',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          // 每张照片时长
          Row(
            children: [
              const Expanded(
                child: Text('每张照片显示时长'),
              ),
              Text('${durationPerPhoto.toStringAsFixed(1)} 秒'),
            ],
          ),
          Slider(
            value: durationPerPhoto,
            min: 1,
            max: 10,
            divisions: 18,
            onChanged: onDurationChanged,
          ),

          const SizedBox(height: 8),

          // 转场效果
          Row(
            children: [
              const Expanded(
                child: Text('转场效果'),
              ),
              DropdownButton<String>(
                value: transitionType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'fade', child: Text('淡入淡出')),
                  DropdownMenuItem(value: 'slide', child: Text('滑动')),
                  DropdownMenuItem(value: 'dissolve', child: Text('溶解')),
                  DropdownMenuItem(value: 'none', child: Text('无')),
                ],
                onChanged: (value) {
                  if (value != null) onTransitionChanged(value);
                },
              ),
            ],
          ),

          const Divider(height: 24),

          // 文字标签
          Text(
            '文字标签',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('显示日期'),
            value: includeDateLabel,
            onChanged: onDateLabelChanged,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('显示体重'),
            value: includeWeightLabel,
            onChanged: onWeightLabelChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
