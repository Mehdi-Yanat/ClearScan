import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart'; // AppColors, AppPreferences, themeModeNotifier
import '../widgets/app_bottom_bar.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

// Storage card stays dark navy in both themes.
const _heroBackground = Color(0xFF0F2A33);
const _heroMutedText = Color(0xFFB7CDD2);
const _heroAccent = Color(0xFF2CC4CF);

/// Text/icon color that stays readable on the primary color in each theme
/// (bright teal in dark mode needs dark text, deep teal in light mode needs white).
Color _onPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0B1E26)
    : Colors.white;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _languageKey = 'profile_language';
  static const _appVersion = '1.0.0';

  final String _name = 'John Doe';
  final String _email = 'john.doe@email.com';
  final String _plan = 'Free plan';

  final double _usedGb = 2.4;
  final double _totalGb = 5;

  SharedPreferences? _prefs;
  bool _backupOn = false;
  bool _lockOn = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = p;
      _backupOn = p.getBool(AppSettings.autoBackup) ?? false;
      _lockOn = p.getBool(AppSettings.appLock) ?? false;
      _language = p.getString(_languageKey) ?? 'English';
    });
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _updateThemeMode(String value) async {
    final mode = _stringToThemeMode(value);
    // This is the SAME notifier MaterialApp listens to (defined in app_theme.dart).
    themeModeNotifier.value = mode;
    await AppPreferences.setThemeMode(mode);
  }

  String get _initials {
    final parts = _name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    _loadPrefs();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    String? prefsKey, // null = the caller persists the value itself
    required ValueChanged<String> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(sheetContext),
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
                    color: AppColors.ink(sheetContext),
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
                    color: AppColors.ink(sheetContext),
                  ),
                ),
                trailing: option == current
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.primary(sheetContext),
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => onPicked(picked));
    if (prefsKey != null) _prefs?.setString(prefsKey, picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    final rows = <_ProfileRowData>[
      _ProfileRowData(
        icon: Icons.cloud_outlined,
        label: 'Backup & Sync',
        value: _backupOn ? 'On' : 'Off',
        onTap: _openSettings,
      ),
      _ProfileRowData(
        icon: Icons.shield_outlined,
        label: 'App Lock',
        value: _lockOn ? 'On' : 'Off',
        onTap: _openSettings,
      ),
      _ProfileRowData(
        icon: Icons.language_rounded,
        label: 'Language',
        value: _language,
        onTap: () => _pickOption(
          title: 'Language',
          options: const ['English', 'Français', 'العربية', 'Deutsch'],
          current: _language,
          prefsKey: _languageKey,
          onPicked: (v) => _language = v,
        ),
      ),
      _ProfileRowData(
        icon: Icons.dark_mode_outlined,
        label: 'Appearance',
        value: _themeModeToString(themeModeNotifier.value),
        // No prefsKey: AppPreferences.setThemeMode already persists it in the
        // lowercase format getThemeMode() expects.
        onTap: () => _pickOption(
          title: 'Appearance',
          options: const ['System', 'Light', 'Dark'],
          current: _themeModeToString(themeModeNotifier.value),
          onPicked: _updateThemeMode,
        ),
      ),
      _ProfileRowData(
        icon: Icons.star_outline_rounded,
        label: 'Rate ClearScan',
        onTap: () => _snack('TODO: open store listing (in_app_review)'),
      ),
      _ProfileRowData(
        icon: Icons.help_outline_rounded,
        label: 'Help & Support',
        onTap: () => _snack('TODO: open help center / email'),
      ),
      _ProfileRowData(
        icon: Icons.info_outline_rounded,
        label: 'About',
        value: 'v$_appVersion',
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'ClearScan',
          applicationVersion: _appVersion,
          applicationLegalese: 'Scan Anything. Save Everything.',
        ),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: AppColors.surface(context),
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 3,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Row(
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openSettings,
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 25,
                      color: AppColors.ink(context),
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AccountCard(
                initials: _initials,
                name: _name,
                email: _email,
                plan: _plan,
              ),
              const SizedBox(height: 14),
              _StorageCard(usedGb: _usedGb, totalGb: _totalGb),
              const SizedBox(height: 14),
              // Material (not Container) so the InkWell ripples are visible.
              Material(
                color: AppColors.surface(context),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      _ProfileRow(data: rows[i]),
                      if (i < rows.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 58,
                          color: AppColors.border(context),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Cards ─────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.plan,
  });

  final String initials;
  final String name;
  final String email;
  final String plan;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primary,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _onPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    // Translucent tint stays visible on the card in both themes.
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    plan,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.usedGb, required this.totalGb});

  final double usedGb;
  final double totalGb;

  @override
  Widget build(BuildContext context) {
    final fraction = totalGb <= 0 ? 0.0 : (usedGb / totalGb).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: _heroBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.border(context)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage',
            style: TextStyle(fontSize: 12, color: _heroMutedText),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${usedGb.toStringAsFixed(1)} GB',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${totalGb.toStringAsFixed(0)} GB used',
                style: const TextStyle(fontSize: 12, color: _heroMutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(height: 8, color: _heroAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── List rows ─────────────────────────────

class _ProfileRowData {
  const _ProfileRowData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.data});

  final _ProfileRowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 14),
          child: Row(
            children: [
              Icon(data.icon, size: 22, color: AppColors.primary(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink(context),
                  ),
                ),
              ),
              if (data.value != null) ...[
                Text(
                  data.value!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textHint(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
