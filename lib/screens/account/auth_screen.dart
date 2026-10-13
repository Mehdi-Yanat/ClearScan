import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart' as loc;
import '../../services/auth/supabase_auth_service.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _creatingAccount = false;
  bool _busy = false;
  bool _awaitingGoogleSignIn = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    SupabaseAuthService.currentUser.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    SupabaseAuthService.currentUser.removeListener(_onAuthChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_awaitingGoogleSignIn ||
        SupabaseAuthService.currentUser.value == null ||
        !mounted) {
      return;
    }
    _awaitingGoogleSignIn = false;
    Navigator.of(context).maybePop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_creatingAccount) {
        final response = await SupabaseAuthService.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _message = loc.AppLocalizations.of(context)!.authCheckEmail;
            _isError = false;
          });
        } else {
          Navigator.of(context).pop();
        }
      } else {
        await SupabaseAuthService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _isError = true;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _message = error.toString();
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!SupabaseAuthService.isGoogleSignInConfigured) {
      setState(() {
        _message = loc.AppLocalizations.of(context)!.authGoogleNotConfigured;
        _isError = true;
      });
      return;
    }

    _awaitingGoogleSignIn = true;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await SupabaseAuthService.signInWithGoogle();
      if (mounted && SupabaseAuthService.currentUser.value != null) {
        _awaitingGoogleSignIn = false;
        Navigator.of(context).maybePop();
      }
    } on GoogleSignInException catch (error, stackTrace) {
      _awaitingGoogleSignIn = false;
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (error.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() {
          _message = error.description ?? error.code.name;
          _isError = true;
        });
      }
    } on AuthException catch (error, stackTrace) {
      _awaitingGoogleSignIn = false;
      debugPrint('Supabase Google token exchange failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _message = error.message;
          _isError = true;
        });
      }
    } on Exception catch (error, stackTrace) {
      _awaitingGoogleSignIn = false;
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _message = error.toString();
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateEmail(String? value, loc.AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@')) return l10n.authInvalidEmail;
    return null;
  }

  String? _validatePassword(String? value, loc.AppLocalizations l10n) {
    if ((value ?? '').length < 6) return l10n.authPasswordTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = loc.AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        foregroundColor: AppColors.ink(context),
        title: Text(_creatingAccount ? l10n.authCreateAccount : l10n.authTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              _creatingAccount
                  ? l10n.authSignUpSubtitle
                  : l10n.authSignInSubtitle,
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (!SupabaseAuthService.isConfigured) ...[
              Text(
                l10n.authBackendNotConfigured,
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authBackendSetupInstructions,
                style: TextStyle(color: AppColors.textMuted(context)),
              ),
              if (SupabaseAuthService.configurationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  SupabaseAuthService.configurationError!,
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy || !SupabaseAuthService.isGoogleSignInConfigured
                      ? null
                      : _signInWithGoogle,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: Text(l10n.authContinueWithGoogle),
                ),
              ),
              if (!SupabaseAuthService.isGoogleSignInConfigured) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.authGoogleNotConfigured,
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.authOr,
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border(context))),
                ],
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_creatingAccount) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.authFullName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            (value?.trim().isNotEmpty ?? false)
                            ? null
                            : l10n.authNameRequired,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.authEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) => _validateEmail(value, l10n),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _creatingAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.authPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) => _validatePassword(value, l10n),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isError
                                ? AppColors.danger
                                : AppColors.primary(context),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _creatingAccount
                                    ? l10n.authCreateAccount
                                    : l10n.authSignIn,
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _creatingAccount = !_creatingAccount;
                              _message = null;
                            }),
                      child: Text(
                        _creatingAccount
                            ? l10n.authHaveAccount
                            : l10n.authNeedAccount,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
