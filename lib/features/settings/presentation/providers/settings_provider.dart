import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app.dart';

/// 设置状态
class SettingsState {
  final bool isDarkMode;
  final String weightUnit;
  final String heightUnit;
  final double? height;
  final double? targetWeight;

  const SettingsState({
    this.isDarkMode = false,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.height,
    this.targetWeight,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? weightUnit,
    String? heightUnit,
    double? height,
    double? targetWeight,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
    );
  }
}

/// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// 设置 Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

/// 设置 Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);

    state = SettingsState(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      weightUnit: prefs.getString('weightUnit') ?? 'kg',
      heightUnit: prefs.getString('heightUnit') ?? 'cm',
      height: prefs.getDouble('height'),
      targetWeight: prefs.getDouble('targetWeight'),
    );

    // 应用主题
    _ref.read(themeModeProvider.notifier).state =
        state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('isDarkMode', value);

    state = state.copyWith(isDarkMode: value);

    // 更新主题
    _ref.read(themeModeProvider.notifier).state =
        value ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString('weightUnit', unit);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setHeightUnit(String unit) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString('heightUnit', unit);
    state = state.copyWith(heightUnit: unit);
  }

  Future<void> setHeight(double height) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('height', height);
    state = state.copyWith(height: height);
  }

  Future<void> setTargetWeight(double weight) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('targetWeight', weight);
    state = state.copyWith(targetWeight: weight);
  }

  Future<void> clearAllData() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.clear();

    // 重置状态
    state = const SettingsState();

    // TODO: 清除数据库
  }
}
