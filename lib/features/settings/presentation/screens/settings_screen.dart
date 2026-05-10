import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/settings_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 外观设置
          _SettingsSection(
            title: '外观',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setDarkMode(value);
                  },
                ),
              ),
            ],
          ),

          // 单位设置
          _SettingsSection(
            title: '单位',
            children: [
              _SettingsTile(
                icon: Icons.scale_outlined,
                title: '体重单位',
                subtitle: settings.weightUnit,
                onTap: () => _showUnitSelector(context, ref),
              ),
              _SettingsTile(
                icon: Icons.height_outlined,
                title: '身高单位',
                subtitle: settings.heightUnit,
                onTap: () => _showHeightUnitSelector(context, ref),
              ),
            ],
          ),

          // 个人信息
          _SettingsSection(
            title: '个人信息',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: '身高',
                subtitle: settings.height != null ? '${settings.height} cm' : '未设置',
                onTap: () => _showHeightInput(context, ref),
              ),
              _SettingsTile(
                icon: Icons.flag_outlined,
                title: '目标体重',
                subtitle: settings.targetWeight != null
                    ? '${settings.targetWeight} ${settings.weightUnit}'
                    : '未设置',
                onTap: () => context.push('/goals'),
              ),
            ],
          ),

          // 数据管理
          _SettingsSection(
            title: '数据管理',
            children: [
              _SettingsTile(
                icon: Icons.download_outlined,
                title: '导出数据',
                subtitle: '导出为 CSV 文件',
                onTap: () => _exportData(context, ref),
              ),
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: '导入数据',
                subtitle: '从 CSV 文件导入',
                onTap: () => _importData(context),
              ),
              _SettingsTile(
                icon: Icons.delete_outline,
                title: '清除所有数据',
                titleColor: AppColors.error,
                onTap: () => _showClearDataConfirmation(context, ref),
              ),
            ],
          ),

          // 关于
          _SettingsSection(
            title: '关于',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: '版本',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '使用条款',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: '反馈建议',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showUnitSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('公斤 (kg)'),
              onTap: () {
                ref.read(settingsProvider.notifier).setWeightUnit('kg');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('磅 (lb)'),
              onTap: () {
                ref.read(settingsProvider.notifier).setWeightUnit('lb');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('斤'),
              onTap: () {
                ref.read(settingsProvider.notifier).setWeightUnit('斤');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightUnitSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('厘米 (cm)'),
              onTap: () {
                ref.read(settingsProvider.notifier).setHeightUnit('cm');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('英尺 (ft)'),
              onTap: () {
                ref.read(settingsProvider.notifier).setHeightUnit('ft');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightInput(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置身高'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '身高 (cm)',
            hintText: '请输入身高',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final height = double.tryParse(controller.text);
              if (height != null) {
                ref.read(settingsProvider.notifier).setHeight(height);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  void _importData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能开发中...')),
    );
  }

  void _showClearDataConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要清除所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清除')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 设置区块
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing16,
            AppDimensions.spacing24,
            AppDimensions.spacing16,
            AppDimensions.spacing8,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// 设置项
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
