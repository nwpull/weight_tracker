import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/photo_management/presentation/screens/photo_timeline_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/video_generation/presentation/screens/video_generator_screen.dart';
import '../../features/weight_chart/presentation/screens/weight_chart_screen.dart';
import '../../features/weight_entry/presentation/screens/weight_entry_screen.dart';
import '../../features/weight_history/presentation/screens/weight_history_screen.dart';
import '../../features/weight_history/presentation/screens/home_screen.dart';

/// 路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      // 首页（Dashboard）
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 体重录入
      GoRoute(
        path: '/weight-entry',
        name: 'weightEntry',
        builder: (context, state) => const WeightEntryScreen(),
      ),

      // 体重历史
      GoRoute(
        path: '/weight-history',
        name: 'weightHistory',
        builder: (context, state) => const WeightHistoryScreen(),
      ),

      // 体重趋势图表
      GoRoute(
        path: '/weight-chart',
        name: 'weightChart',
        builder: (context, state) => const WeightChartScreen(),
      ),

      // 照片时间线
      GoRoute(
        path: '/photo-timeline',
        name: 'photoTimeline',
        builder: (context, state) => const PhotoTimelineScreen(),
      ),

      // 视频生成
      GoRoute(
        path: '/video-generator',
        name: 'videoGenerator',
        builder: (context, state) => const VideoGeneratorScreen(),
      ),

      // 目标设置
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),

      // 设置
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],

    // 错误处理
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '页面未找到: ${state.uri}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// 路由名称常量
class AppRoutes {
  AppRoutes._();

  static const String home = '/home';
  static const String weightEntry = '/weight-entry';
  static const String weightHistory = '/weight-history';
  static const String weightChart = '/weight-chart';
  static const String photoTimeline = '/photo-timeline';
  static const String videoGenerator = '/video-generator';
  static const String goals = '/goals';
  static const String settings = '/settings';
}
