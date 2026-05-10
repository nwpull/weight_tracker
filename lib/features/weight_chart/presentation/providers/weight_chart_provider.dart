import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/daos/weight_record_dao.dart';

/// 图表周期
enum ChartPeriod {
  week,
  month,
  threeMonths,
  year,
}

/// 图表数据
class WeightChartData {
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final ChartPeriod period;
  final WeightStats stats;

  const WeightChartData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.period,
    required this.stats,
  });

  factory WeightChartData.empty(ChartPeriod period) => WeightChartData(
        spots: [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 100,
        period: period,
        stats: const WeightStats(
          average: 0,
          max: 0,
          min: 0,
          change: 0,
          count: 0,
        ),
      );

  bool get hasData => spots.isNotEmpty;

  DateTime getDateForX(double x) {
    return DateTime.fromMillisecondsSinceEpoch(x.toInt());
  }
}

/// 体重统计
class WeightStats {
  final double average;
  final double max;
  final double min;
  final double change;
  final int count;

  const WeightStats({
    required this.average,
    required this.max,
    required this.min,
    required this.change,
    required this.count,
  });
}

/// 体重图表 Provider
final weightChartProvider =
    FutureProvider.family<WeightChartData, ChartPeriod>((ref, period) async {
  final db = ref.watch(databaseProvider);
  final dao = WeightRecordDao(db);

  final now = DateTime.now();
  DateTime startDate;

  switch (period) {
    case ChartPeriod.week:
      startDate = now.subtract(const Duration(days: 7));
    case ChartPeriod.month:
      startDate = DateTime(now.year, now.month - 1, now.day);
    case ChartPeriod.threeMonths:
      startDate = DateTime(now.year, now.month - 3, now.day);
    case ChartPeriod.year:
      startDate = DateTime(now.year - 1, now.month, now.day);
  }

  final records = await dao.getRecordsByDateRange(startDate, now);

  if (records.isEmpty) {
    return WeightChartData.empty(period);
  }

  // 转换为图表数据点
  final spots = records.asMap().entries.map((entry) {
    final record = entry.value;
    return FlSpot(
      record.date.millisecondsSinceEpoch.toDouble(),
      record.weight,
    );
  }).toList();

  // 计算统计
  final weights = records.map((r) => r.weight).toList();
  final avg = weights.reduce((a, b) => a + b) / weights.length;
  final max = weights.reduce((a, b) => a > b ? a : b);
  final min = weights.reduce((a, b) => a < b ? a : b);
  final change = records.last.weight - records.first.weight;

  // 计算Y轴范围
  final yMin = ((min - 2).clamp(0, double.infinity)).toDouble();
  final yMax = (max + 2).toDouble();

  return WeightChartData(
    spots: spots,
    minX: spots.first.x,
    maxX: spots.last.x,
    minY: yMin,
    maxY: yMax,
    period: period,
    stats: WeightStats(
      average: avg,
      max: max,
      min: min,
      change: change,
      count: records.length,
    ),
  );
});
