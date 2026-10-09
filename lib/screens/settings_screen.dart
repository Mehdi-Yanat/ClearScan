import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/app_lock_service.dart';

class AppSettings {
  static const autoDetectEdges = 'settings_auto_detect_edges';
  static const autoCapture = 'settings_auto_capture';
  static const quality = 'settings_default_quality';
  static const format = 'settings_default_format';
  static const appLock = AppLockService.preferenceKey;
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
    final l10n = AppLocalizations.of(context);
    if (!mounted || l10n == null) return;

    // Get all strings we need for the dialog before showing it
    final clearCacheTitle = l10n.settingsClearCacheTitle;
    final clearCacheMessage = l10n.settingsClearCacheMessage;
    final settingsCancel = l10n.settingsCancel;
    final settingsClear = l10n.settingsClear;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          clearCacheTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          clearCacheMessage,
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
              settingsCancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              settingsClear,
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
    if (!mounted) return;
    _snack(l10n.settingsCacheCleared);
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

  Future<void> _setAppLock(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (value) {
        final authenticated = await AppLockService.enable(
          l10n.appLockAuthReason,
        );
        if (!authenticated) {
          _snack(l10n.appLockAuthenticationFailed);
          return;
        }
      } else {
        await AppLockService.disable();
      }
      if (mounted) setState(() => _appLock = value);
    } on Exception catch (error) {
      _snack(l10n.appLockAuthenticationError(error.toString()));
    }
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: option == current
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
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
    final l10n = AppLocalizations.of(context);
    String message;
    if (l10n != null) {
      message = l10n.settingsOpenLinkPlaceholder(title);
    } else {
      message = '{title}: add your link';
    }
    _snack(message);
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/home'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Back',
          ),
          titleSpacing: 0,
          title: Text(
            AppLocalizations.of(context)!.settingsTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        body: _prefs == null
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  _Section(
                    title: AppLocalizations.of(context)!
                        .settingsSectionScanning,
                    children: [
                      _ToggleRow(
                        label: AppLocalizations.of(context)!
                            .settingsAutoDetectEdges,
                        value: _autoDetectEdges,
                        onChanged: (v) => _setBool(
                          AppSettings.autoDetectEdges,
                          v,
                          () => _autoDetectEdges = v,
                        ),
                      ),
                      _ToggleRow(
                        label: AppLocalizations.of(context)!
                            .settingsAutoCapture,
                        value: _autoCapture,
                        onChanged: (v) => _setBool(
                          AppSettings.autoCapture,
                          v,
                          () => _autoCapture = v,
                        ),
                      ),
                      _ValueRow(
                        label: AppLocalizations.of(context)!
                            .settingsDefaultQuality,
                        value: _quality,
                        onTap: () => _pickOption(
                          title: AppLocalizations.of(context)!
                              .settingsDefaultQuality,
                          options: <String>[
                            AppLocalizations.of(context)!.settingsQualityLow,
                            AppLocalizations.of(context)!.settingsQualityMedium,
                            AppLocalizations.of(context)!.settingsQualityHigh,
                          ],
                          current: _quality,
                          prefsKey: AppSettings.quality,
                          onPicked: (v) => _quality = v,
                        ),
                      ),
                      _ValueRow(
                        label: AppLocalizations.of(context)!
                            .settingsDefaultFormat,
                        value: _format,
                        onTap: () => _pickOption(
                          title: AppLocalizations.of(context)!
                              .settingsDefaultFormat,
                          options: [
                            AppLocalizations.of(context)!.settingsFormatPdf,
                            AppLocalizations.of(context)!.settingsFormatJpg,
                          ],
                          current: _format,
                          prefsKey: AppSettings.format,
                          onPicked: (v) => _format = v,
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: AppLocalizations.of(context)!
                        .settingsSectionSecurity,
                    children: [
                      _ToggleRow(
                        label: AppLocalizations.of(context)!.settingsAppLock,
                        value: _appLock,
                        onChanged: _setAppLock,
                      ),
                      _ToggleRow(
                        label: AppLocalizations.of(context)!
                            .settingsHideInRecents,
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
                    title: AppLocalizations.of(context)!
                        .settingsSectionStorageSync,
                    children: [
                      _ToggleRow(
                        label: AppLocalizations.of(context)!.settingsAutoBackup,
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
                        label: AppLocalizations.of(context)!.settingsClearCache,
                        value: _formatBytes(_cacheBytes),
                        onTap: _clearCache,
                      ),
                    ],
                  ),
                  _Section(
                    title: AppLocalizations.of(context)!.settingsSectionAbout,
                    children: [
                      _ValueRow(
                        label: AppLocalizations.of(context)!
                            .settingsPrivacyPolicy,
                        onTap: () => _openLink(
                          AppLocalizations.of(context)!.settingsPrivacyPolicy,
                        ),
                      ),
                      _ValueRow(
                        label: AppLocalizations.of(context)!
                            .settingsTermsOfService,
                        onTap: () => _openLink(
                          AppLocalizations.of(context)!.settingsTermsOfService,
                        ),
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
                      color: Theme.of(context).colorScheme.outline,
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
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.3),
                inactiveThumbColor: Theme.of(context).colorScheme.outline,
                inactiveTrackColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
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
