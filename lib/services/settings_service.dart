import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyThemeMode = 'themeMode';
  static const _keyAdvanceNoticeDays = 'defaultAdvanceNoticeDays';
  static const _keyNotificationHour = 'notificationHour';
  static const _keyNotificationMinute = 'notificationMinute';

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  // ── themeMode ──────────────────────────────────────────────────────────────

  ThemeMode get themeMode {
    final idx = _prefs.getInt(_keyThemeMode) ?? 0;
    return ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, mode.index);
  }

  // ── defaultAdvanceNoticeDays ───────────────────────────────────────────────

  int get defaultAdvanceNoticeDays =>
      _prefs.getInt(_keyAdvanceNoticeDays) ?? 1;

  Future<void> setDefaultAdvanceNoticeDays(int days) async {
    await _prefs.setInt(_keyAdvanceNoticeDays, days.clamp(1, 30));
  }

  // ── notificationTime ──────────────────────────────────────────────────────

  int get notificationHour => _prefs.getInt(_keyNotificationHour) ?? 9;

  int get notificationMinute => _prefs.getInt(_keyNotificationMinute) ?? 0;

  Future<void> setNotificationTime({required int hour, required int minute}) async {
    await _prefs.setInt(_keyNotificationHour, hour.clamp(0, 23));
    await _prefs.setInt(_keyNotificationMinute, minute.clamp(0, 59));
  }
}
