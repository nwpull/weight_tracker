import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../data/database/app_database.dart';
import '../providers/home_provider.dart';

/// 首页（Dashboard）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(homeStatsProvider);

    return Scaffold(
      body: asyncStats.when(
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const LoadingView(message: '加载数据中...'),
        error: (error, stack) => ErrorView(
          message: '加载失败: $error',
          onRetry: () => ref.invalidate(homeStatsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/weight-entry'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeStats stats) {
    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('体重追踪'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),

        // 内容区域
        SliverPadding(
          padding: AppDimensions.pagePadding,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 当前体重卡片
              _CurrentWeightCard(
                weight: stats.latestWeight,
                change: stats.weightChange,
                hasData: stats.hasData,
              ),

              const SizedBox(height: AppDimensions.spacing16),

              // 快捷操作
              _QuickActionsGrid(),

              const SizedBox(height: AppDimensions.spacing24),

              // 统计摘要
              if (stats.hasData) ...[
                Text(
                  '本月统计',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                _StatsGrid(stats: stats),
              ],

              const SizedBox(height: AppDimensions.spacing24),

              // 最近记录
              Text(
                '最近记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.spacing12),
            ]),
          ),
        ),

        // 最近记录列表
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
          sliver: stats.recentRecords.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyRecordsCard(
                    onAdd: () => context.push('/weight-entry'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = stats.recentRecords[index];
                      return _RecordListTile(record: record);
                    },
                    childCount: stats.recentRecords.length,
                  ),
                ),
        ),

        // 底部间距
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
}

/// 当前体重卡片
class _CurrentWeightCard extends StatelessWidget {
  final double weight;
  final double change;
  final bool hasData;

  const _CurrentWeightCard({
    required this.weight,
    required this.change,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前体重',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasData ? weight.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
            ],
          ),
          if (hasData) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                Icon(
                  change >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: change >= 0
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '相比首次记录',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 快捷操作网格
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.show_chart,
            title: '趋势',
            onTap: () => context.push('/weight-chart'),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.photo_library_outlined,
            title: '照片',
            onTap: () => context.push('/photo-timeline'),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.movie_creation_outlined,
            title: '视频',
            onTap: () => context.push('/video-generator'),
          ),
        ),
      ],
    );
  }
}

/// 快捷操作卡片
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 统计网格
class _StatsGrid extends StatelessWidget {
  final HomeStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '平均',
            value: '${stats.averageWeight.toStringAsFixed(1)} kg',
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: _StatCard(
            title: '最高',
            value: '${stats.maxWeight.toStringAsFixed(1)} kg',
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: _StatCard(
            title: '最低',
            value: '${stats.minWeight.toStringAsFixed(1)} kg',
          ),
        ),
      ],
    );
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// 空记录卡片
class _EmptyRecordsCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRecordsCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.scale_outlined,
            size: 48,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加第一条记录'),
          ),
        ],
      ),
    );
  }
}

/// 记录列表项
class _RecordListTile extends StatelessWidget {
  final WeightRecord record;

  const _RecordListTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM月dd日', 'zh_CN');
    final weekdayFormat = DateFormat('EEEE', 'zh_CN');

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Center(
            child: Text(
              record.weight.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        title: Text(
          '${record.weight.toStringAsFixed(1)} kg',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${dateFormat.format(record.date)} ${weekdayFormat.format(record.date)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: 跳转到详情页
        },
      ),
    );
  }
}
