import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class AppSettings {
  static const autoDetectEdges = 'settings_auto_detect_edges';
  static const autoCapture = 'settings_auto_capture';
  static const quality = 'settings_default_quality';
  static const format = 'settings_default_format';
  static const appLock = 'settings_app_lock';
  static const hideInRecents = 'settings_hide_in_recents';
  static const autoBackup = 'settings_auto_backup';
  static const themeMode = 'settings_theme_mode';

  static const defaultQuality = 'High';
  static const defaultFormat = 'PDF';
  static const ThemeMode defaultThemeMode = ThemeMode.system;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;

  bool _autoDetectEdges = true;
  bool _autoCapture = false;
  String _quality = AppSettings.defaultQuality;
  String _format = AppSettings.defaultFormat;
  bool _appLock = false;
  bool _hideInRecents = false;
  bool _autoBackup = false;
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshCacheSize();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _autoDetectEdges = p.getBool(AppSettings.autoDetectEdges) ?? true;
      _autoCapture = p.getBool(AppSettings.autoCapture) ?? false;
      _quality = p.getString(AppSettings.quality) ?? AppSettings.defaultQuality;
      _format = p.getString(AppSettings.format) ?? AppSettings.defaultFormat;
      _appLock = p.getBool(AppSettings.appLock) ?? false;
      _hideInRecents = p.getBool(AppSettings.hideInRecents) ?? false;
      _autoBackup = p.getBool(AppSettings.autoBackup) ?? false;
    });
  }

  // ── cache ──

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> _refreshCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      final size = await _dirSize(dir);
      if (mounted) setState(() => _cacheBytes = size);
    } catch (_) {
      if (mounted) setState(() => _cacheBytes = null);
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear cache?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Temporary files will be deleted. Your documents are not affected.',
          style: TextStyle(
            fontSize: 13.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final dir = await getTemporaryDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
    await _refreshCacheSize();
    _snack('Cache cleared');
  }

  // ── helpers ──

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setBool(String key, bool value, void Function() apply) {
    setState(apply);
    _prefs?.setBool(key, value);
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required String prefsKey,
    required ValueChanged<String> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface, // ✅ Fixed
                  ),
                ),
                trailing: option == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary, // ✅ Fixed
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => onPicked(picked));
    _prefs?.setString(prefsKey, picked);
  }

  void _openLink(String title) {
    _snack('$title: add your link');
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Fixed
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Fixed
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/home'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onSurface, // ✅ Fixed
            ),
            tooltip: 'Back',
          ),
          titleSpacing: 0,
          title: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface, // ✅ Fixed
            ),
          ),
        ),
        body: _prefs == null
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary, // ✅ Fixed
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  _Section(
                    title: 'SCANNING',
                    children: [
                      _ToggleRow(
                        label: 'Auto-detect edges',
                        value: _autoDetectEdges,
                        onChanged: (v) => _setBool(
                          AppSettings.autoDetectEdges,
                          v,
                          () => _autoDetectEdges = v,
                        ),
                      ),
                      _ToggleRow(
                        label: 'Auto-capture',
                        value: _autoCapture,
                        onChanged: (v) => _setBool(
                          AppSettings.autoCapture,
                          v,
                          () => _autoCapture = v,
                        ),
                      ),
                      _ValueRow(
                        label: 'Default quality',
                        value: _quality,
                        onTap: () => _pickOption(
                          title: 'Default quality',
                          options: const ['Low', 'Medium', 'High'],
                          current: _quality,
                          prefsKey: AppSettings.quality,
                          onPicked: (v) => _quality = v,
                        ),
                      ),
                      _ValueRow(
                        label: 'Default format',
                        value: _format,
                        onTap: () => _pickOption(
                          title: 'Default format',
                          options: const ['PDF', 'JPG'],
                          current: _format,
                          prefsKey: AppSettings.format,
                          onPicked: (v) => _format = v,
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'SECURITY',
                    children: [
                      _ToggleRow(
                        label: 'App lock (PIN / biometric)',
                        value: _appLock,
                        onChanged: (v) {
                          _setBool(AppSettings.appLock, v, () => _appLock = v);
                        },
                      ),
                      _ToggleRow(
                        label: 'Hide in recents',
                        value: _hideInRecents,
                        onChanged: (v) {
                          _setBool(
                            AppSettings.hideInRecents,
                            v,
                            () => _hideInRecents = v,
                          );
                        },
                      ),
                    ],
                  ),
                  _Section(
                    title: 'STORAGE & SYNC',
                    children: [
                      _ToggleRow(
                        label: 'Auto backup',
                        value: _autoBackup,
                        onChanged: (v) {
                          _setBool(
                            AppSettings.autoBackup,
                            v,
                            () => _autoBackup = v,
                          );
                        },
                      ),
                      _ValueRow(
                        label: 'Clear cache',
                        value: _formatBytes(_cacheBytes),
                        onTap: _clearCache,
                      ),
                    ],
                  ),
                  _Section(
                    title: 'ABOUT',
                    children: [
                      _ValueRow(
                        label: 'Privacy policy',
                        onTap: () => _openLink('Privacy policy'),
                      ),
                      _ValueRow(
                        label: 'Terms of service',
                        onTap: () => _openLink('Terms of service'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ───────────────────────────── Building blocks ─────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      color: Theme.of(context).colorScheme.outline, // ✅ Fixed
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // ✅ ADDED: Switch widget that was missing!
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(context).colorScheme.primary
                    .withOpacity(0.3),
                inactiveThumbColor: Theme.of(context).colorScheme.outline,
                inactiveTrackColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
