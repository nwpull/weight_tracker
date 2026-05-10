import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/daos/weight_record_dao.dart';
import '../../../../data/database/tables/goals.dart';

/// 目标信息
class GoalInfo {
  final int id;
  final double targetWeight;
  final double startWeight;
  final double currentWeight;
  final DateTime startDate;
  final DateTime? targetDate;
  final bool isActive;

  const GoalInfo({
    required this.id,
    required this.targetWeight,
    required this.startWeight,
    required this.currentWeight,
    required this.startDate,
    this.targetDate,
    required this.isActive,
  });

  /// 计算进度百分比
  /// 减重目标：startWeight > targetWeight，currentWeight 下降为正进度
  /// 增重目标：startWeight < targetWeight，currentWeight 上升为正进度
  double get progress {
    if (startWeight == targetWeight) return 1.0;
    final total = (startWeight - targetWeight).abs();
    if (total == 0) return 1.0;

    // 计算有方向的进度（减重为正方向）
    final current = startWeight - currentWeight;
    final target = startWeight - targetWeight;

    // 如果方向一致（同正或同负），计算进度比例
    if (current * target > 0) {
      return (current.abs() / total).clamp(0.0, 1.0);
    }
    // 方向相反（反弹），进度为 0
    return 0.0;
  }
}

/// 目标 Provider
final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalInfo?>((ref) {
  return GoalsNotifier(ref);
});

/// 活跃目标 Provider
final activeGoalProvider = FutureProvider<GoalInfo?>((ref) async {
  final db = ref.watch(databaseProvider);

  final activeGoals = await (db.select(db.goals)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)
        ])
        ..limit(1))
      .get();

  if (activeGoals.isEmpty) return null;

  final goal = activeGoals.first;

  // 获取当前体重
  final weightDao = WeightRecordDao(db);
  final latestRecord = await weightDao.getLatestRecord();
  final currentWeight = latestRecord?.weight ?? goal.targetWeight;

  return GoalInfo(
    id: goal.id,
    targetWeight: goal.targetWeight,
    startWeight: goal.targetWeight, // TODO: 存储起始体重
    currentWeight: currentWeight,
    startDate: goal.startDate,
    targetDate: goal.targetDate,
    isActive: goal.isActive,
  );
});

/// 目标 Notifier
class GoalsNotifier extends StateNotifier<GoalInfo?> {
  final Ref _ref;

  GoalsNotifier(this._ref) : super(null) {
    _loadActiveGoal();
  }

  Future<void> _loadActiveGoal() async {
    final db = _ref.read(databaseProvider);

    final activeGoals = await (db.select(db.goals)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .get();

    if (activeGoals.isEmpty) {
      state = null;
      return;
    }

    final goal = activeGoals.first;
    final weightDao = WeightRecordDao(db);
    final latestRecord = await weightDao.getLatestRecord();

    state = GoalInfo(
      id: goal.id,
      targetWeight: goal.targetWeight,
      startWeight: goal.targetWeight,
      currentWeight: latestRecord?.weight ?? goal.targetWeight,
      startDate: goal.startDate,
      targetDate: goal.targetDate,
      isActive: goal.isActive,
    );
  }

  Future<void> createGoal({
    required double targetWeight,
    required DateTime targetDate,
  }) async {
    final db = _ref.read(databaseProvider);

    // 先停用其他目标
    await (db.update(db.goals)..where((t) => t.isActive.equals(true)))
        .write(const GoalsCompanion(isActive: Value(false)));

    // 获取当前体重作为起始体重
    final weightDao = WeightRecordDao(db);
    final latestRecord = await weightDao.getLatestRecord();
    final currentWeight = latestRecord?.weight ?? targetWeight;

    // 创建新目标
    await db.into(db.goals).insert(
          GoalsCompanion(
            targetWeight: Value(targetWeight),
            startDate: Value(DateTime.now()),
            targetDate: Value(targetDate),
            isActive: const Value(true),
          ),
        );

    await _loadActiveGoal();
  }

  Future<void> updateProgress() async {
    await _loadActiveGoal();
  }

  Future<void> deactivateGoal() async {
    if (state == null) return;

    final db = _ref.read(databaseProvider);
    await (db.update(db.goals)..where((t) => t.id.equals(state!.id)))
        .write(const GoalsCompanion(isActive: Value(false)));

    state = null;
  }

  Future<List<GoalInfo>> getAllGoals() async {
    final db = _ref.read(databaseProvider);

    final goals = await (db.select(db.goals)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)
          ]))
        .get();

    return goals.map((goal) {
      return GoalInfo(
        id: goal.id,
        targetWeight: goal.targetWeight,
        startWeight: goal.targetWeight,
        currentWeight: goal.targetWeight,
        startDate: goal.startDate,
        targetDate: goal.targetDate,
        isActive: goal.isActive,
      );
    }).toList();
  }
}
