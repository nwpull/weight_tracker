import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/daos/weight_record_dao.dart';

/// 首页统计 Provider
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = WeightRecordDao(db);

  // 获取所有记录
  final records = await dao.getAllRecords();

  if (records.isEmpty) {
    return HomeStats.empty();
  }

  // 计算统计数据
  final weights = records.map((r) => r.weight).toList();
  final avg = weights.reduce((a, b) => a + b) / weights.length;
  final max = weights.reduce((a, b) => a > b ? a : b);
  final min = weights.reduce((a, b) => a < b ? a : b);

  // 最近5条记录
  final recentRecords = records.take(5).toList();

  return HomeStats(
    hasData: true,
    totalRecords: records.length,
    latestWeight: records.first.weight,
    firstWeight: records.last.weight,
    averageWeight: avg,
    maxWeight: max,
    minWeight: min,
    weightChange: records.first.weight - records.last.weight,
    recentRecords: recentRecords,
  );
});

/// 首页统计数据
class HomeStats {
  final bool hasData;
  final int totalRecords;
  final double latestWeight;
  final double firstWeight;
  final double averageWeight;
  final double maxWeight;
  final double minWeight;
  final double weightChange;
  final List<WeightRecord> recentRecords;

  const HomeStats({
    required this.hasData,
    required this.totalRecords,
    required this.latestWeight,
    required this.firstWeight,
    required this.averageWeight,
    required this.maxWeight,
    required this.minWeight,
    required this.weightChange,
    required this.recentRecords,
  });

  factory HomeStats.empty() => const HomeStats(
        hasData: false,
        totalRecords: 0,
        latestWeight: 0,
        firstWeight: 0,
        averageWeight: 0,
        maxWeight: 0,
        minWeight: 0,
        weightChange: 0,
        recentRecords: [],
      );
}
