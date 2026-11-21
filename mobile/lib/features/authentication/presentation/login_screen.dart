import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/phone_number.dart';

/// Landing: clear Sign in / Create account choices. Phone-code sign-in is secondary.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  String _q(BuildContext context, String path, [String? mode]) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final q = <String>[
      if (mode != null) 'mode=$mode',
      if (from != null) 'from=${Uri.encodeComponent(from)}',
    ];
    return q.isEmpty ? path : '$path?${q.join('&')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                Icon(Icons.apartment_rounded, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.md),
                Text(t.authWelcomeTitle,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  key: const Key('signInButton'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => context.push(_q(context, '/login/email', 'signin')),
                  child: Text(t.authSignInTitle),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  key: const Key('signUpButton'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => context.push(_q(context, '/login/email', 'signup')),
                  child: Text(t.authCreateAccount),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  key: const Key('continueGuestButton'),
                  onPressed: () => context.go('/home'),
                  child: Text(t.authContinueGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  ConsumerState<PhoneLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final phone = normalizeIraqiPhone(_controller.text);
    if (phone == null) {
      setState(() => _error = t.authInvalidPhone);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider)!.sendOtp(phone);
      if (mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.push(
          from == null ? '/verify' : '/verify?from=${Uri.encodeComponent(from)}',
          extra: phone,
        );
      }
    } catch (e) {
      debugPrint('auth error: $e');
      if (mounted) {
        setState(() => _error = kDebugMode ? '$e' : t.authGenericError);
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
                Icon(Icons.apartment_rounded, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.md),
                Text(t.authWelcomeTitle,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(t.authPhoneHelp,
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                Directionality(
                  textDirection: TextDirection.ltr, // phone numbers are always LTR
                  child: TextField(
                    key: const Key('phoneField'),
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t.authPhoneLabel,
                      prefixText: '+964  ',
                      hintText: '770 123 4567',
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const Key('sendCodeButton'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.authSendCode),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
