import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class AppLockService {
  static const preferenceKey = 'settings_app_lock';

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  static final LocalAuthentication _authentication = LocalAuthentication();

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    enabled.value = preferences.getBool(preferenceKey) ?? false;
  }

  static Future<bool> enable(String localizedReason) async {
    if (!await _authentication.isDeviceSupported()) {
      throw Exception('This device does not support device authentication.');
    }

    final authenticated = await _authentication.authenticate(
      localizedReason: localizedReason,
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) return false;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, true);
    enabled.value = true;
    return true;
  }

  static Future<void> disable() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(preferenceKey, false);
    enabled.value = false;
  }

  static Future<bool> authenticate(String localizedReason) {
    return _authentication.authenticate(
      localizedReason: localizedReason,
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  late bool _locked;
  bool _authenticating = false;
  bool _wasBackgrounded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locked = AppLockService.enabled.value;
    WidgetsBinding.instance.addObserver(this);
    AppLockService.enabled.addListener(_onEnabledChanged);
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLockService.enabled.removeListener(_onEnabledChanged);
    super.dispose();
  }

  void _onEnabledChanged() {
    if (!AppLockService.enabled.value && mounted) {
      setState(() {
        _locked = false;
        _error = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      if (AppLockService.enabled.value && mounted) {
        setState(() {
          _locked = true;
          _error = null;
        });
      }
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (AppLockService.enabled.value && mounted) {
        setState(() {
          _locked = true;
          _error = null;
        });
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating || !_locked || !AppLockService.enabled.value) return;

    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final authenticated = await AppLockService.authenticate(
        AppLocalizations.of(context)!.appLockAuthReason,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _locked = !authenticated;
        _error = authenticated ? null : l10n.appLockAuthenticationFailed;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.appLockAuthenticationError(
          error.toString(),
        );
      });
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;

    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ExcludeSemantics(child: widget.child),
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 56, color: colors.primary),
                      const SizedBox(height: 20),
                      Text(
                        l10n.appLockUnlockTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _authenticating ? null : _authenticate,
                        icon: _authenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(l10n.appLockUnlockButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
