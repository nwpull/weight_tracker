import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/weight_records.dart';
import 'tables/photo_metadata.dart';
import 'tables/goals.dart';

part 'app_database.g.dart';

/// 应用数据库
@DriftDatabase(tables: [
  WeightRecords,
  PhotoMetadata,
  Goals,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本迁移逻辑
      },
    );
  }
}

/// 打开数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'weight_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
