import 'package:flutter/material.dart';

import 'app_lock_service.dart';

class AppSettings {
  static const quality = 'settings_default_quality';
  static const format = 'settings_default_format';
  static const grid = 'settings_scanner_grid';
  static const appLock = AppLockService.preferenceKey;
  static const hideInRecents = 'settings_hide_in_recents';
  static const autoBackup = 'settings_auto_backup';
  static const themeMode = 'settings_theme_mode';

  static const defaultQuality = 'High';
  static const defaultFormat = 'PDF';
  static const ThemeMode defaultThemeMode = ThemeMode.system;
}
