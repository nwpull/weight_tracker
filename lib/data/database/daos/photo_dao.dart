import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/photo_metadata.dart';

part 'photo_dao.g.dart';

/// 照片元数据数据访问对象
@DriftAccessor(tables: [PhotoMetadata])
class PhotoDao extends DatabaseAccessor<AppDatabase>
    with _$PhotoDaoMixin {
  PhotoDao(super.db);

  /// 获取所有照片
  Future<List<PhotoMetadataData>> getAllPhotos() {
    return (select(photoMetadata)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ])).get();
  }

  /// 监听所有照片
  Stream<List<PhotoMetadataData>> watchAllPhotos() {
    return (select(photoMetadata)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ])).watch();
  }

  /// 根据体重记录 ID 获取照片
  Future<List<PhotoMetadataData>> getPhotosByWeightRecordId(int recordId) {
    return (select(photoMetadata)
          ..where((t) => t.weightRecordId.equals(recordId)))
        .get();
  }

  /// 监听体重记录的照片
  Stream<List<PhotoMetadataData>> watchPhotosByWeightRecordId(int recordId) {
    return (select(photoMetadata)
          ..where((t) => t.weightRecordId.equals(recordId)))
        .watch();
  }

  /// 获取单张照片
  Future<PhotoMetadataData?> getPhotoById(int id) {
    return (select(photoMetadata)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 插入照片
  Future<int> insertPhoto(PhotoMetadataCompanion photo) {
    return into(photoMetadata).insert(photo);
  }

  /// 删除照片
  Future<int> deletePhoto(int id) {
    return (delete(photoMetadata)..where((t) => t.id.equals(id))).go();
  }

  /// 删除体重记录的所有照片
  Future<int> deletePhotosByWeightRecordId(int recordId) {
    return (delete(photoMetadata)
          ..where((t) => t.weightRecordId.equals(recordId)))
        .go();
  }

  /// 获取带日期的照片列表（用于时间线）
  Future<List<PhotoWithDate>> getPhotosWithDates() async {
    final photos = await getAllPhotos();
    // 这里需要 join weight_records 表获取日期
    // 简化处理，使用 createdAt
    return photos.map((p) => PhotoWithDate(
          photo: p,
          date: p.createdAt,
        )).toList();
  }
}

/// 带日期的照片信息
class PhotoWithDate {
  final PhotoMetadataData photo;
  final DateTime date;

  const PhotoWithDate({
    required this.photo,
    required this.date,
  });
}
