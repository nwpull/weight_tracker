import 'package:drift/drift.dart';

/// 目标设置表
class Goals extends Table {
  /// 主键 ID
  IntColumn get id => integer().autoIncrement()();

  /// 目标体重（kg）
  RealColumn get targetWeight => real()();

  /// 开始日期
  DateTimeColumn get startDate => dateTime()();

  /// 目标日期
  DateTimeColumn get targetDate => dateTime().nullable()();

  /// 备注
  TextColumn get note => text().nullable()();

  /// 是否激活
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
