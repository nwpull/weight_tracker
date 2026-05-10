import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/weight_records.dart';

part 'weight_record_dao.g.dart';

/// 体重记录数据访问对象
@DriftAccessor(tables: [WeightRecords])
class WeightRecordDao extends DatabaseAccessor<AppDatabase>
    with _$WeightRecordDaoMixin {
  WeightRecordDao(super.db);

  /// 获取所有体重记录（按日期降序）
  Future<List<WeightRecord>> getAllRecords() {
    return (select(weightRecords)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ])).get();
  }

  /// 监听所有体重记录
  Stream<List<WeightRecord>> watchAllRecords() {
    return (select(weightRecords)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ])).watch();
  }

  /// 根据日期范围获取记录
  Future<List<WeightRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(weightRecords)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 监听日期范围内的记录
  Stream<List<WeightRecord>> watchRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(weightRecords)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// 获取单条记录
  Future<WeightRecord?> getRecordById(int id) {
    return (select(weightRecords)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 插入记录
  Future<int> insertRecord(WeightRecordsCompanion record) {
    return into(weightRecords).insert(record);
  }

  /// 更新记录
  Future<int> updateRecord(WeightRecord record) {
    return (update(weightRecords)..where((t) => t.id.equals(record.id)))
        .write(WeightRecordsCompanion(
          weight: Value(record.weight),
          date: Value(record.date),
          note: Value(record.note),
        ));
  }

  /// 删除记录
  Future<int> deleteRecord(int id) {
    return (delete(weightRecords)..where((t) => t.id.equals(id))).go();
  }

  /// 获取最新一条记录
  Future<WeightRecord?> getLatestRecord() {
    return (select(weightRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 获取统计信息
  Future<WeightStats> getStats() async {
    final records = await getAllRecords();
    if (records.isEmpty) {
      return WeightStats.empty();
    }

    final weights = records.map((r) => r.weight).toList();
    final avg = weights.reduce((a, b) => a + b) / weights.length;
    final max = weights.reduce((a, b) => a > b ? a : b);
    final min = weights.reduce((a, b) => a < b ? a : b);

    return WeightStats(
      count: records.length,
      average: avg,
      max: max,
      min: min,
      latest: records.first.weight,
      first: records.last.weight,
    );
  }

  /// 获取日期范围内的统计
  Future<WeightStats> getStatsByDateRange(DateTime start, DateTime end) async {
    final records = await getRecordsByDateRange(start, end);
    if (records.isEmpty) {
      return WeightStats.empty();
    }

    final weights = records.map((r) => r.weight).toList();
    final avg = weights.reduce((a, b) => a + b) / weights.length;
    final max = weights.reduce((a, b) => a > b ? a : b);
    final min = weights.reduce((a, b) => a < b ? a : b);

    return WeightStats(
      count: records.length,
      average: avg,
      max: max,
      min: min,
      latest: records.last.weight,
      first: records.first.weight,
    );
  }
}

/// 体重统计信息
class WeightStats {
  final int count;
  final double average;
  final double max;
  final double min;
  final double latest;
  final double first;

  const WeightStats({
    required this.count,
    required this.average,
    required this.max,
    required this.min,
    required this.latest,
    required this.first,
  });

  factory WeightStats.empty() => const WeightStats(
        count: 0,
        average: 0,
        max: 0,
        min: 0,
        latest: 0,
        first: 0,
      );

  /// 计算变化量
  double get change => latest - first;

  /// 是否有数据
  bool get hasData => count > 0;
}
