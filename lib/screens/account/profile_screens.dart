import 'dart:async';

import 'package:clear_scan/screens/scanning/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cloud_storage_screen.dart';
import 'auth_screen.dart';
import '../../l10n/app_localizations.dart' as loc;
import '../../services/app/app_lock_service.dart';
import '../../services/app/app_settings.dart';
import '../../services/auth/supabase_auth_service.dart';
import '../../services/documents/cloud_document_storage.dart';
import '../../theme/app_theme.dart'; // AppColors, AppPreferences, themeModeNotifier, localeNotifier
import '../../widgets/navigation/app_bottom_bar.dart';
import '../../widgets/feedback/app_snackbar.dart';
import 'settings_screen.dart';

// Storage card stays dark navy in both themes.
const _heroBackground = Color(0xFF0F2A33);
const _heroMutedText = Color(0xFFB7CDD2);
const _heroAccent = Color(0xFF2CC4CF);

// Text/icon color that stays readable on the primary color in each theme
// (bright teal in dark mode needs dark text, deep teal in light mode needs white).
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
  String? _appVersion;

  SharedPreferences? _prefs;
  bool _lockOn = false;
  bool _signingOut = false;
  bool _loadingCloudUsage = false;
  CloudStorageUsage? _cloudUsage;
  String? _cloudStorageError;
  String _language = 'English'; // display string

  // Mapping between display strings and Locale objects
  static final Map<String, Locale> _languageToLocale = {
    'English': const Locale('en'),
    'العربية': const Locale('ar'),
    'Deutsch': const Locale('de'),
  };
  static final Map<Locale, String> _localeToLanguage = {
    const Locale('en'): 'English',
    const Locale('ar'): 'العربية',
    const Locale('de'): 'Deutsch',
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    SupabaseAuthService.currentUser.addListener(_onAccountChanged);
    _refreshCloudUsage();
    themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeChanged);
    SupabaseAuthService.currentUser.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onAccountChanged() {
    _refreshCloudUsage();
  }

  Future<void> _refreshCloudUsage() async {
    if (SupabaseAuthService.currentUser.value == null) {
      if (mounted) {
        setState(() {
          _cloudUsage = null;
          _cloudStorageError = null;
          _loadingCloudUsage = false;
        });
      }
      return;
    }

    setState(() {
      _loadingCloudUsage = true;
      _cloudStorageError = null;
    });
    try {
      final usage = await loadCloudStorageUsage();
      if (mounted) setState(() => _cloudUsage = usage);
    } on Exception catch (error) {
      if (mounted) setState(() => _cloudStorageError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingCloudUsage = false);
    }
  }

  Future<void> _openCloudStorage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CloudStorageScreen()));
    await _refreshCloudUsage();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final locale = await AppPreferences.getLocale();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _prefs = p;
      _appVersion = packageInfo.version;
      _lockOn = p.getBool(AppSettings.appLock) ?? false;
      // Load locale code and map to display string
      _language = _localeToLanguage[locale] ?? 'English';
      // Update the notifier as well
      localeNotifier.value = locale;
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _openScanner() {
    ScannerScreen.open(context);
  }

  Future<void> _handleAccountAction(User? user) async {
    if (user == null) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
      return;
    }

    setState(() => _signingOut = true);
    try {
      await SupabaseAuthService.signOut();
    } on Exception catch (error) {
      _snack('Could not sign out: $error');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    _loadPrefs();
  }

  Future<void> _toggleAppLock() async {
    final l10n = loc.AppLocalizations.of(context)!;
    try {
      if (_lockOn) {
        await AppLockService.disable();
      } else {
        final authenticated = await AppLockService.enable(
          l10n.appLockAuthReason,
        );
        if (!authenticated) {
          _snack(l10n.appLockAuthenticationFailed);
          return;
        }
      }
      if (mounted) setState(() => _lockOn = !_lockOn);
    } on Exception catch (error) {
      _snack(l10n.appLockAuthenticationError(error.toString()));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message);
  }

  Future<void> _openHelpAndSupport() async {
    const email = 'mehdi.yanat3106@outlook.fr';
    final l10n = loc.AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'ClearScan Support'},
    );

    try {
      if (!await launchUrl(uri) && mounted) {
        _snack(l10n.helpEmailLaunchFailed(email));
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _snack('${l10n.helpEmailLaunchFailed(email)} (${error.code})');
      }
    }
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    String? prefsKey, // null = the caller persists the value itself
    required FutureOr<void> Function(String) onPicked,
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
    try {
      await onPicked(picked);
      if (prefsKey != null) await _prefs?.setString(prefsKey, picked);
    } on Exception catch (error) {
      _snack('Could not save this setting: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    final rows = <_ProfileRowData>[
      _ProfileRowData(
        icon: Icons.cloud_outlined,
        label: loc.AppLocalizations.of(context)!.backupAndSync,
        value: loc.AppLocalizations.of(context)!.cloudManageBackups,
        onTap: () {
          if (SupabaseAuthService.currentUser.value == null) {
            _handleAccountAction(null);
          } else {
            _openCloudStorage();
          }
        },
      ),
      _ProfileRowData(
        icon: Icons.shield_outlined,
        label: loc.AppLocalizations.of(context)!.appLock,
        value: _lockOn
            ? loc.AppLocalizations.of(context)!.on
            : loc.AppLocalizations.of(context)!.off,
        onTap: _toggleAppLock,
      ),
      _ProfileRowData(
        icon: Icons.language_rounded,
        label: loc.AppLocalizations.of(context)!.language,
        value: _language,
        onTap: () => _pickOption(
          title: loc.AppLocalizations.of(context)!.language,
          options: const ['English', 'العربية', 'Deutsch'],
          current: _language,
          prefsKey: null,
          onPicked: (v) async {
            setState(() {
              _language = v;
            });
            final locale = _languageToLocale[v] ?? const Locale('en');
            localeNotifier.value = locale;
            await AppPreferences.setLocale(locale);
          },
        ),
      ),
      _ProfileRowData(
        icon: Icons.dark_mode_outlined,
        label: loc.AppLocalizations.of(context)!.appearance,
        value: themeModeNotifier.value == ThemeMode.light
            ? loc.AppLocalizations.of(context)!.light
            : themeModeNotifier.value == ThemeMode.dark
            ? loc.AppLocalizations.of(context)!.dark
            : loc.AppLocalizations.of(context)!.system,
        // No prefsKey: AppPreferences.setThemeMode already persists it in the
        // lowercase format getThemeMode() expects.
        onTap: () => _pickOption(
          title: loc.AppLocalizations.of(context)!.appearance,
          options: const ['System', 'Light', 'Dark'],
          current: _themeModeToString(themeModeNotifier.value),
          onPicked: _updateThemeMode,
        ),
      ),
      _ProfileRowData(
        icon: Icons.help_outline_rounded,
        label: loc.AppLocalizations.of(context)!.helpAndSupport,
        onTap: _openHelpAndSupport,
      ),
      _ProfileRowData(
        icon: Icons.info_outline_rounded,
        label: loc.AppLocalizations.of(context)!.about,
        value: 'v$_appVersion',
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'ClearScan',
          applicationVersion: _appVersion,
          applicationLegalese: loc.AppLocalizations.of(context)!
              .scanAnythingSaveEverything,
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
                    loc.AppLocalizations.of(context)!.profile,
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
                    tooltip: loc.AppLocalizations.of(context)!.settingsTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<User?>(
                valueListenable: SupabaseAuthService.currentUser,
                builder: (context, user, _) {
                  final l10n = loc.AppLocalizations.of(context)!;
                  final metadataName = user?.userMetadata?['full_name'];
                  final name =
                      metadataName is String && metadataName.trim().isNotEmpty
                      ? metadataName.trim()
                      : user?.email?.split('@').first ?? l10n.authGuestTitle;
                  return _AccountCard(
                    initials: _initials(name),
                    name: name,
                    email: user?.email ?? l10n.authGuestDescription,
                    plan: user == null ? null : l10n.freePlan,
                    actionLabel: user == null
                        ? l10n.authSignIn
                        : l10n.authSignOut,
                    onAction: _signingOut
                        ? null
                        : () => _handleAccountAction(user),
                  );
                },
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<User?>(
                valueListenable: SupabaseAuthService.currentUser,
                builder: (context, user, _) => _StorageCard(
                  usage: _cloudUsage,
                  loading: _loadingCloudUsage,
                  error: _cloudStorageError,
                  signedIn: user != null,
                  onManage: () => user == null
                      ? _handleAccountAction(null)
                      : _openCloudStorage(),
                ),
              ),
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
    required this.actionLabel,
    required this.onAction,
  });

  final String initials;
  final String name;
  final String email;
  final String? plan;
  final String actionLabel;
  final VoidCallback? onAction;

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
      child: Column(
        children: [
          Row(
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
                    if (plan != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          plan!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onAction,
              icon: Icon(
                plan == null ? Icons.login_rounded : Icons.logout_rounded,
                size: 18,
              ),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.usage,
    required this.loading,
    required this.error,
    required this.signedIn,
    required this.onManage,
  });

  final CloudStorageUsage? usage;
  final bool loading;
  final String? error;
  final bool signedIn;
  final VoidCallback? onManage;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = loc.AppLocalizations.of(context)!;

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
          Text(
            l10n.cloudStorage,
            style: const TextStyle(fontSize: 12, color: _heroMutedText),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                loading
                    ? l10n.cloudStorageLoading
                    : _formatBytes(usage?.sizeBytes ?? 0),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.cloudBackupCount(usage?.fileCount ?? 0),
                style: const TextStyle(fontSize: 12, color: _heroMutedText),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Color(0xFFFFA8A8), fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onManage,
            style: TextButton.styleFrom(
              foregroundColor: _heroAccent,
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              signedIn ? Icons.cloud_sync_outlined : Icons.login_rounded,
              size: 18,
            ),
            label: Text(signedIn ? l10n.cloudManageBackups : l10n.authSignIn),
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
  final VoidCallback? onTap;
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
