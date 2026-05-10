import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/weight_chart_provider.dart';
import '../widgets/period_selector.dart';
import '../widgets/stats_summary_card.dart';

/// 体重趋势图表页面
class WeightChartScreen extends ConsumerStatefulWidget {
  const WeightChartScreen({super.key});

  @override
  ConsumerState<WeightChartScreen> createState() => _WeightChartScreenState();
}

class _WeightChartScreenState extends ConsumerState<WeightChartScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.month;

  @override
  Widget build(BuildContext context) {
    final chartDataAsync = ref.watch(weightChartProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('体重趋势'),
      ),
      body: chartDataAsync.when(
        data: (data) => _buildContent(context, data),
        loading: () => const LoadingView(message: '加载图表数据...'),
        error: (error, stack) => ErrorView(
          message: '加载失败: $error',
          onRetry: () => ref.invalidate(weightChartProvider),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeightChartData data) {
    return ListView(
      padding: AppDimensions.pagePadding,
      children: [
        // 周期选择器
        PeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() => _selectedPeriod = period);
          },
        ),

        const SizedBox(height: AppDimensions.spacing24),

        // 统计摘要
        if (data.hasData)
          StatsSummaryCard(
            stats: data.stats,
          ),

        const SizedBox(height: AppDimensions.spacing24),

        // 图表
        Container(
          height: 300,
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: data.hasData
              ? _WeightLineChart(data: data)
              : _EmptyChartPlaceholder(),
        ),

        const SizedBox(height: AppDimensions.spacing24),

        // 图例说明
        _ChartLegend(),

        const SizedBox(height: 48),
      ],
    );
  }
}

/// 体重折线图
class _WeightLineChart extends StatelessWidget {
  final WeightChartData data;

  const _WeightLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textHint.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateBottomInterval(),
              getTitlesWidget: (value, meta) {
                return _BottomTitle(
                  value: value,
                  spots: data.spots,
                  period: data.period,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _calculateInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: data.minX,
        maxX: data.maxX,
        minY: data.minY,
        maxY: data.maxY,
        lineBarsData: [
          LineChartBarData(
            spots: data.spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surfaceDark,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = data.getDateForX(spot.x);
                return LineTooltipItem(
                  '${DateFormat('MM/dd').format(date)}\n${spot.y.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval() {
    final range = data.maxY - data.minY;
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    return 5;
  }

  double _calculateBottomInterval() {
    final count = data.spots.length;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 7;
    return 10;
  }
}

/// 底部标题
class _BottomTitle extends StatelessWidget {
  final double value;
  final List<FlSpot> spots;
  final ChartPeriod period;

  const _BottomTitle({
    required this.value,
    required this.spots,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final index = value.toInt();
    if (index < 0 || index >= spots.length) {
      return const SizedBox.shrink();
    }

    final spot = spots[index];
    final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());

    String text;
    switch (period) {
      case ChartPeriod.week:
        text = DateFormat('E', 'zh_CN').format(date);
      case ChartPeriod.month:
        text = DateFormat('MM/dd').format(date);
      case ChartPeriod.threeMonths:
        text = DateFormat('MM/dd').format(date);
      case ChartPeriod.year:
        text = DateFormat('MM月').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// 空图表占位
class _EmptyChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: AppColors.textHint.withOpacity(0.3),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            '暂无数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            '记录体重后即可查看趋势图',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

/// 图表图例
class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '体重趋势',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 4),
          Text(
            '点击数据点查看详情',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}
