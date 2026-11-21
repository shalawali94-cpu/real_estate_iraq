import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late bool _createMode;
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modeInit) {
      _modeInit = true;
      _createMode = GoRouterState.of(context).uri.queryParameters['mode'] == 'signup';
    }
  }

  bool _modeInit = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    final loginPhone = (!_createMode && !email.contains('@')) ? normalizeIraqiPhone(email) : null;
    if (loginPhone == null && (!_emailRe.hasMatch(email) || email.length > 120)) {
      setState(() => _error = _createMode ? t.validationEmail : t.authWrongCredentials);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = t.authPasswordShort);
      return;
    }
    String? phone;
    if (_createMode) {
      final n = _name.text.trim();
      if (n.length < 2 || n.length > 80) {
        setState(() => _error = t.validationName);
        return;
      }
      phone = normalizeIraqiPhone(_phone.text);
      if (phone == null) {
        setState(() => _error = t.validationPhoneIraq);
        return;
      }
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final repo = ref.read(authRepositoryProvider)!;
      if (_createMode) {
        await repo.signUpWithEmail(email, password,
            fullName: _name.text.trim(), phone: phone!);
      } else {
        if (loginPhone != null) {
          final res = await ref
              .read(apiClientProvider)!
              .post('/api/v1/auth/phone-login', {'phone': loginPhone, 'password': password});
          await Supabase.instance.client.auth.setSession(res['refresh_token'] as String);
        } else {
          await repo.signInWithEmail(email, password);
        }
      }
      if (!mounted) return;
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      // go() replaces the stack; the router sends new accounts to onboarding.
      context.go((from != null && from.startsWith('/')) ? from : '/home');
    } catch (e) {
      debugPrint('auth error: $e');
      if (mounted) {
        setState(() => _error = e.toString().contains('invalid_credentials') ||
                e.toString().contains('UNAUTHENTICATED') ||
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
                Text(_createMode ? t.authCreateAccount : t.authSignInTitle,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xl),
                if (_createMode) ...[
                  TextField(
                    key: const Key('nameField'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: t.fieldFullName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      key: const Key('phoneField'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: t.fieldPhoneIraq, prefixText: '+964 '),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const Key('emailField'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                        labelText: _createMode ? t.fieldEmail : t.fieldEmailOrPhone),
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
                      : Text(_createMode ? t.authCreateAccount : t.authSignInTitle),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() {
                    _createMode = !_createMode;
                    _error = null;
                  }),
                  child: Text(_createMode ? t.authToSignIn : t.authToCreate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
