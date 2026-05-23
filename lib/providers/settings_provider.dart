import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

class SettingsNotifier extends AsyncNotifier<SettingsService> {
  SettingsService? _preloaded;

  /// Used in tests to inject a pre-built SettingsService.
  void preload(SettingsService service) {
    _preloaded = service;
  }

  @override
  Future<SettingsService> build() async {
    if (_preloaded != null) return _preloaded!;
    return SettingsService.load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final svc = state.value;
    if (svc == null) return;
    await svc.setThemeMode(mode);
    ref.notifyListeners();
  }

  Future<void> setDefaultAdvanceNoticeDays(int days) async {
    final svc = state.value;
    if (svc == null) return;
    await svc.setDefaultAdvanceNoticeDays(days);
    ref.notifyListeners();
  }

  Future<void> setNotificationTime({required int hour, required int minute}) async {
    final svc = state.value;
    if (svc == null) return;
    await svc.setNotificationTime(hour: hour, minute: minute);
    ref.notifyListeners();
  }

  Future<void> setOnboardingDone() async {
    final svc = state.value;
    if (svc == null) return;
    await svc.setOnboardingDone();
    ref.notifyListeners();
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsService>(
  SettingsNotifier.new,
);

/// Derived provider: resolves the current ThemeMode (falls back to system while loading).
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).whenData((s) => s.themeMode).valueOrNull ??
      ThemeMode.system;
});
