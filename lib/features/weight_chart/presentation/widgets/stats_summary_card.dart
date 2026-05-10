import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/weight_chart_provider.dart';

/// 统计摘要卡片
class StatsSummaryCard extends StatelessWidget {
  final WeightStats stats;

  const StatsSummaryCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '统计摘要',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            children: [
              _StatItem(
                label: '平均',
                value: '${stats.average.toStringAsFixed(1)} kg',
                icon: Icons.analytics_outlined,
              ),
              _StatItem(
                label: '最高',
                value: '${stats.max.toStringAsFixed(1)} kg',
                icon: Icons.trending_up,
                color: AppColors.error,
              ),
              _StatItem(
                label: '最低',
                value: '${stats.min.toStringAsFixed(1)} kg',
                icon: Icons.trending_down,
                color: AppColors.success,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '变化',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  Icon(
                    stats.change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: stats.change >= 0 ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.change >= 0 ? '+' : ''}${stats.change.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: stats.change >= 0 ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '记录数',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${stats.count} 次',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
