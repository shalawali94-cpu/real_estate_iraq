import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/auth_repository.dart';

/// Email + password sign-in / sign-up. Everyone (users and staff) can use it;
/// roles are decided server-side, never here.
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});
  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createMode = false;
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (!_emailRe.hasMatch(email) || email.length > 120) {
      setState(() => _error = t.validationEmail);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = t.authPasswordShort);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider)!;
      if (_createMode) {
        await repo.signUpWithEmail(email, password);
      } else {
        await repo.signInWithEmail(email, password);
      }
      if (!mounted) return;
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      // go() replaces the stack; the router sends new accounts to onboarding.
      context.go((from != null && from.startsWith('/')) ? from : '/home');
    } catch (e) {
      debugPrint('auth error: $e');
      if (mounted) {
        setState(() => _error = e.toString().contains('invalid_credentials') ||
                e.toString().contains('Invalid login')
            ? t.authWrongCredentials
            : (kDebugMode ? '$e' : t.authGenericError));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                Text(_createMode ? t.authCreateAccount : t.authEmailSignIn,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xl),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const Key('emailField'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: t.fieldEmail),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const Key('passwordField'),
                    controller: _password,
                    obscureText: _hide,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t.authPassword,
                      errorText: _error,
                      errorMaxLines: 3,
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const Key('emailSubmitButton'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_createMode ? t.authCreateAccount : t.authEmailSignIn),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() {
                    _createMode = !_createMode;
                    _error = null;
                  }),
                  child: Text(_createMode ? t.authToSignIn : t.authToCreate),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(t.authUsePhone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
