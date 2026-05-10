import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/goals_provider.dart';
import '../widgets/goal_progress_ring.dart';

/// 目标设置页面
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(activeGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showGoalHistory(context),
          ),
        ],
      ),
      body: goalAsync.when(
        data: (goal) => _buildContent(context, goal),
        loading: () => const LoadingView(message: '加载中...'),
        error: (error, stack) => ErrorView(
          message: '加载失败: $error',
          onRetry: () => ref.invalidate(activeGoalProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('设置新目标'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GoalInfo? goal) {
    if (goal == null) {
      return _EmptyGoalState(
        onAddGoal: () => _showAddGoalDialog(context),
      );
    }

    return SingleChildScrollView(
      padding: AppDimensions.pagePadding,
      child: Column(
        children: [
          // 目标进度环
          GoalProgressRing(
            currentWeight: goal.currentWeight,
            targetWeight: goal.targetWeight,
            startWeight: goal.startWeight,
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // 目标详情卡片
          _GoalDetailCard(goal: goal),

          const SizedBox(height: AppDimensions.spacing24),

          // 进度统计
          _ProgressStats(goal: goal),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final targetWeightController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('设置目标'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '目标体重 (kg)',
                  hintText: '请输入目标体重',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('目标日期'),
                subtitle: Text(DateFormat('yyyy年MM月dd日').format(targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => targetDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final targetWeight = double.tryParse(targetWeightController.text);
                if (targetWeight == null || targetWeight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效的目标体重')),
                  );
                  return;
                }

                Navigator.pop(context);
                await ref.read(goalsProvider.notifier).createGoal(
                      targetWeight: targetWeight,
                      targetDate: targetDate,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('目标已设置')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '历史目标',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                future: ref.read(goalsProvider.notifier).getAllGoals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }

                  final goals = snapshot.data ?? [];
                  if (goals.isEmpty) {
                    return const Center(child: Text('暂无历史目标'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _GoalHistoryItem(goal: goal);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空目标状态
class _EmptyGoalState extends StatelessWidget {
  final VoidCallback onAddGoal;

  const _EmptyGoalState({required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            '还没有设置目标',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            '设置一个目标来追踪你的进度',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          ElevatedButton.icon(
            onPressed: onAddGoal,
            icon: const Icon(Icons.add),
            label: const Text('设置目标'),
          ),
        ],
      ),
    );
  }
}

/// 目标详情卡片
class _GoalDetailCard extends StatelessWidget {
  final GoalInfo goal;

  const _GoalDetailCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailItem(
                label: '起始体重',
                value: '${goal.startWeight.toStringAsFixed(1)} kg',
              ),
              _DetailItem(
                label: '当前体重',
                value: '${goal.currentWeight.toStringAsFixed(1)} kg',
                highlight: true,
              ),
              _DetailItem(
                label: '目标体重',
                value: '${goal.targetWeight.toStringAsFixed(1)} kg',
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '开始日期',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                DateFormat('yyyy年MM月dd日').format(goal.startDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目标日期',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  DateFormat('yyyy年MM月dd日').format(goal.targetDate!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 详情项
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highlight ? AppColors.primary : null,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// 进度统计
class _ProgressStats extends StatelessWidget {
  final GoalInfo goal;

  const _ProgressStats({required this.goal});

  @override
  Widget build(BuildContext context) {
    final lost = goal.startWeight - goal.currentWeight;
    final remaining = goal.currentWeight - goal.targetWeight;
    final daysPassed = DateTime.now().difference(goal.startDate).inDays;
    final daysRemaining = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;

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
            '进度统计',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '已减重',
                  value: '${lost >= 0 ? "-" : "+"}${lost.abs().toStringAsFixed(1)} kg',
                  color: lost >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '距离目标',
                  value: '${remaining.toStringAsFixed(1)} kg',
                  color: remaining <= 0 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '已坚持',
                  value: '$daysPassed 天',
                ),
              ),
              if (daysRemaining != null)
                Expanded(
                  child: _StatItem(
                    label: '剩余天数',
                    value: '$daysRemaining 天',
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
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// 历史目标项
class _GoalHistoryItem extends StatelessWidget {
  final GoalInfo goal;

  const _GoalHistoryItem({required this.goal});

  @override
  Widget build(BuildContext context) {
    final achieved = goal.currentWeight <= goal.targetWeight;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: achieved
              ? AppColors.success.withOpacity(0.1)
              : AppColors.textHint.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          achieved ? Icons.check : Icons.flag_outlined,
          color: achieved ? AppColors.success : AppColors.textHint,
        ),
      ),
      title: Text('目标: ${goal.targetWeight.toStringAsFixed(1)} kg'),
      subtitle: Text(
        '${DateFormat('yyyy/MM/dd').format(goal.startDate)} - ${goal.targetDate != null ? DateFormat('yyyy/MM/dd').format(goal.targetDate!) : "进行中"}',
      ),
      trailing: achieved
          ? const Text('已达成', style: TextStyle(color: AppColors.success))
          : const Text('未达成', style: TextStyle(color: AppColors.textHint)),
    );
  }
}
