import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/daos/photo_dao.dart';

/// 照片日期信息
class PhotoWithDateInfo {
  final int id;
  final String filePath;
  final DateTime date;
  final double? weight;

  const PhotoWithDateInfo({
    required this.id,
    required this.filePath,
    required this.date,
    this.weight,
  });
}

/// 照片时间线 Provider
final photoTimelineProvider =
    FutureProvider<List<PhotoWithDateInfo>>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = PhotoDao(db);

  final photos = await dao.getAllPhotos();

  // 转换为带日期信息的列表
  return photos.map((p) {
    return PhotoWithDateInfo(
      id: p.id!,
      filePath: p.filePath,
      date: p.createdAt!,
    );
  }).toList();
});

/// 选中的照片 Provider
final selectedPhotosProvider = StateProvider<Set<int>>((ref) => {});

/// 清除选中的照片
void clearSelectedPhotos(WidgetRef ref) {
  ref.read(selectedPhotosProvider.notifier).state = {};
}
