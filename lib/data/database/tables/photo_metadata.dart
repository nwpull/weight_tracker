import 'package:drift/drift.dart';

import 'weight_records.dart';

/// 照片元数据表
class PhotoMetadata extends Table {
  /// 主键 ID
  IntColumn get id => integer().autoIncrement()();

  /// 关联的体重记录 ID
  IntColumn get weightRecordId => integer().references(WeightRecords, #id)();

  /// 本地文件路径
  TextColumn get filePath => text()();

  /// 缩略图路径
  TextColumn get thumbnailPath => text().nullable()();

  /// 图片宽度
  IntColumn get width => integer().nullable()();

  /// 图片高度
  IntColumn get height => integer().nullable()();

  /// 文件大小（bytes）
  IntColumn get fileSize => integer().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
