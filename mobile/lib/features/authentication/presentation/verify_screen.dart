import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/phone_number.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, required this.phone});
  final String phone;
  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  static const _cooldown = 30;
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;
  int _left = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _left = _left - 1 < 0 ? 0 : _left - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context);
    final code = normalizeOtp(_controller.text);
    if (code == null) {
      setState(() => _error = t.authInvalidCode);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider)!.verifyOtp(widget.phone, code);
      // Router redirect reacts to the new session.
    } catch (e) {
      debugPrint('auth error: $e');
      if (mounted) {
        setState(() => _error = kDebugMode ? '$e' : t.authGenericError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final t = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider)!.sendOtp(widget.phone);
      _startTimer();
    } catch (_) {
      if (mounted) setState(() => _error = t.authGenericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                Text(t.authEnterCodeTitle,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(t.authCodeSentTo(widget.phone),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.lg),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const Key('otpField'),
                    controller: _controller,
                    autofocus: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
                    onSubmitted: (_) => _verify(),
                    decoration: InputDecoration(counterText: '', errorText: _error),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('verifyButton'),
                  onPressed: _busy ? null : _verify,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.authVerify),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _left > 0 ? null : _resend,
                  child: Text(_left > 0 ? '${t.authResend} ($_left)' : t.authResend),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(t.authChangeNumber),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
