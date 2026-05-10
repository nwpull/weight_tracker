import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../data/database/daos/weight_record_dao.dart';

/// 体重历史记录 Provider
final weightHistoryProvider =
    AsyncNotifierProvider<WeightHistoryNotifier, List<WeightRecord>>(
  () => WeightHistoryNotifier(),
);

/// 体重历史记录 Notifier
class WeightHistoryNotifier extends AsyncNotifier<List<WeightRecord>> {
  @override
  Future<List<WeightRecord>> build() async {
    return _loadRecords();
  }

  Future<List<WeightRecord>> _loadRecords() async {
    final db = ref.read(databaseProvider);
    final dao = WeightRecordDao(db);
    return dao.getAllRecords();
  }

  /// 刷新记录
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadRecords());
  }

  /// 删除记录
  Future<void> deleteRecord(int id) async {
    final db = ref.read(databaseProvider);
    final dao = WeightRecordDao(db);
    await dao.deleteRecord(id);
    await refresh();
  }

  /// 清空所有记录
  Future<void> clearAllRecords() async {
    final db = ref.read(databaseProvider);
    await db.delete(db.weightRecords).go();
    await refresh();
  }
}
