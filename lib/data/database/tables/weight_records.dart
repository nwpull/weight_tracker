import 'package:drift/drift.dart';

/// 体重记录表
class WeightRecords extends Table {
  /// 主键 ID
  IntColumn get id => integer().autoIncrement()();

  /// 体重值（kg）
  RealColumn get weight => real()();

  /// 记录日期
  DateTimeColumn get date => dateTime()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
