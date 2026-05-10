import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/photo_timeline_provider.dart';

/// 照片时间线页面
class PhotoTimelineScreen extends ConsumerStatefulWidget {
  const PhotoTimelineScreen({super.key});

  @override
  ConsumerState<PhotoTimelineScreen> createState() => _PhotoTimelineScreenState();
}

class _PhotoTimelineScreenState extends ConsumerState<PhotoTimelineScreen> {
  final Set<int> _selectedPhotos = {};

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(photoTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('照片时间线'),
        actions: [
          if (_selectedPhotos.isNotEmpty)
            TextButton.icon(
              onPressed: () => context.push('/video-generator'),
              icon: const Icon(Icons.movie_creation_outlined),
              label: Text('生成视频 (${_selectedPhotos.length})'),
            ),
        ],
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return _EmptyState(
              onAddPhoto: () => context.push('/weight-entry'),
            );
          }
          return _PhotoTimelineList(
            photos: photos,
            selectedPhotos: _selectedPhotos,
            onPhotoToggle: _togglePhoto,
          );
        },
        loading: () => const LoadingView(message: '加载照片中...'),
        error: (error, stack) => ErrorView(
          message: '加载失败: $error',
          onRetry: () => ref.invalidate(photoTimelineProvider),
        ),
      ),
      floatingActionButton: _selectedPhotos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/video-generator'),
              icon: const Icon(Icons.movie_creation),
              label: const Text('生成视频'),
            )
          : null,
    );
  }

  void _togglePhoto(int photoId) {
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }
    });
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPhoto;

  const _EmptyState({required this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            '暂无照片',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            '在记录体重时上传照片',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          ElevatedButton.icon(
            onPressed: onAddPhoto,
            icon: const Icon(Icons.add),
            label: const Text('添加记录'),
          ),
        ],
      ),
    );
  }
}

/// 照片时间线列表
class _PhotoTimelineList extends StatelessWidget {
  final List<PhotoWithDateInfo> photos;
  final Set<int> selectedPhotos;
  final Function(int) onPhotoToggle;

  const _PhotoTimelineList({
    required this.photos,
    required this.selectedPhotos,
    required this.onPhotoToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 按月份分组
    final groupedPhotos = _groupByMonth(photos);

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      itemCount: groupedPhotos.length,
      itemBuilder: (context, index) {
        final entry = groupedPhotos.entries.elementAt(index);
        return _MonthSection(
          month: entry.key,
          photos: entry.value,
          selectedPhotos: selectedPhotos,
          onPhotoToggle: onPhotoToggle,
        );
      },
    );
  }

  Map<String, List<PhotoWithDateInfo>> _groupByMonth(List<PhotoWithDateInfo> photos) {
    final Map<String, List<PhotoWithDateInfo>> grouped = {};

    for (final photo in photos) {
      final monthKey = DateFormat('yyyy年MM月').format(photo.date);
      grouped.putIfAbsent(monthKey, () => []).add(photo);
    }

    return grouped;
  }
}

/// 月份区块
class _MonthSection extends StatelessWidget {
  final String month;
  final List<PhotoWithDateInfo> photos;
  final Set<int> selectedPhotos;
  final Function(int) onPhotoToggle;

  const _MonthSection({
    required this.month,
    required this.photos,
    required this.selectedPhotos,
    required this.onPhotoToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          child: Text(
            month,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),

        // 照片网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return _PhotoGridItem(
              photo: photo,
              isSelected: selectedPhotos.contains(photo.id),
              onTap: () => onPhotoToggle(photo.id),
            );
          },
        ),

        const SizedBox(height: AppDimensions.spacing16),
      ],
    );
  }
}

/// 照片网格项
class _PhotoGridItem extends StatelessWidget {
  final PhotoWithDateInfo photo;
  final bool isSelected;
  final VoidCallback onTap;

  const _PhotoGridItem({
    required this.photo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 照片
          Container(
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 占位图
                  const Icon(
                    Icons.image_outlined,
                    color: AppColors.textHint,
                  ),
                  // TODO: 实际图片加载
                  // Image.file(
                  //   File(photo.filePath),
                  //   fit: BoxFit.cover,
                  // ),
                ],
              ),
            ),
          ),

          // 选中状态
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

          // 日期标签
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('MM/dd').format(photo.date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
