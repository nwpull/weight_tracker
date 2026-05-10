import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// 照片选择组件
class PhotoPickerWidget extends StatelessWidget {
  final List<String> photos;
  final bool isProcessing;
  final Function(String?) onPhotoAdded;
  final Function(int) onPhotoRemoved;
  final VoidCallback onOcrRequested;

  const PhotoPickerWidget({
    super.key,
    required this.photos,
    required this.isProcessing,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    required this.onOcrRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '照片',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (photos.isNotEmpty)
              TextButton.icon(
                onPressed: isProcessing ? null : onOcrRequested,
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined, size: 18),
                label: Text(isProcessing ? '识别中...' : 'OCR识别'),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 已选照片
              ...photos.asMap().entries.map((entry) {
                return _PhotoThumbnail(
                  path: entry.value,
                  index: entry.key,
                  onRemove: () => onPhotoRemoved(entry.key),
                );
              }),

              // 添加按钮
              _AddPhotoButton(
                onCamera: () async {
                  // 模拟相机拍照
                  onPhotoAdded(null);
                },
                onGallery: () async {
                  // 模拟从相册选择
                  onPhotoAdded(null);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          '提示：拍摄体重秤照片后点击"OCR识别"可自动读取体重',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      ],
    );
  }
}

/// 照片缩略图
class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final int index;
  final VoidCallback onRemove;

  const _PhotoThumbnail({
    required this.path,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: AppDimensions.spacing8),
      child: Stack(
        children: [
          // 照片
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.textHint.withOpacity(0.2),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textHint,
                    ),
                  );
                },
              ),
            ),
          ),

          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加照片按钮
class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AddPhotoButton({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '添加照片',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}
