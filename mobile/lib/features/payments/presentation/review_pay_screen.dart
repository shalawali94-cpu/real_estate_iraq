import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/money.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/payment_repository.dart';

final _reviewPropertyProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final row = await Supabase.instance.client
      .from('properties')
      .select('title,publication_status,price_amount,price_currency,transaction_type')
      .eq('id', id)
      .maybeSingle();
  return row;
});

final _feeProvider = FutureProvider.autoDispose.family<int?, String>(
    (ref, transactionType) async =>
        ref.watch(paymentRepositoryProvider)?.publishingFee(transactionType));

/// Last wizard step: review, submit, pay the publishing fee, wait for moderation.
/// Payment success is only ever read from the server, never decided by the app.
class ReviewPayScreen extends ConsumerStatefulWidget {
  const ReviewPayScreen({super.key, required this.propertyId});
  final String propertyId;
  @override
  ConsumerState<ReviewPayScreen> createState() => _ReviewPayScreenState();
}

class _ReviewPayScreenState extends ConsumerState<ReviewPayScreen> {
  String _provider = 'FIB';
  bool _busy = false;
  bool _notConfigured = false;
  String? _orderId;
  String? _message;

  void _reload() => ref.invalidate(_reviewPropertyProvider(widget.propertyId));

  Future<void> _guard(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final t = AppLocalizations.of(context);
    try {
      await job();
    } on ApiException catch (e) {
      debugPrint('payment api error: $e');
      if (mounted) setState(() => _message = kDebugMode ? '$e' : t.authGenericError);
    } catch (e) {
      debugPrint('payment error: $e');
      if (mounted) setState(() => _message = kDebugMode ? '$e' : t.authGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() => _guard(() async {
        await ref.read(paymentRepositoryProvider)!.submit(widget.propertyId);
        _reload();
      });

  Future<void> _pay() => _guard(() async {
        final repo = ref.read(paymentRepositoryProvider)!;
        final locale = Localizations.localeOf(context).languageCode;
        try {
          final res = await repo.createOrder(
              propertyId: widget.propertyId, provider: _provider, locale: locale);
          final order = res['order'] as Map<String, dynamic>;
          final payment = (res['payment'] as Map?)?.cast<String, dynamic>() ?? const {};
          final links = (payment['appLinks'] as Map?)?.cast<String, dynamic>();
          final url = (payment['formUrl'] as String?) ??
              (links?['personal'] as String?) ??
              (links?['business'] as String?);
          if (mounted) setState(() => _orderId = order['id'] as String);
          if (url != null) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
          _reload();
        } on ApiException catch (e) {
          if (e.code == 'PAYMENT_PROVIDER_NOT_CONFIGURED') {
            if (mounted) setState(() => _notConfigured = true);
            return;
          }
          rethrow;
        }
      });

  Future<void> _check() => _guard(() async {
        final t = AppLocalizations.of(context);
        final res = await ref.read(paymentRepositoryProvider)!.orderStatus(_orderId!);
        final status = (res['order'] as Map)['status'] as String;
        _reload();
        if (!mounted) return;
        setState(() => _message = switch (status) {
              'paid' => t.payStatusPaid,
              'failed' || 'cancelled' || 'expired' => t.payStatusFailed,
              _ => t.payStatusPending,
            });
      });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final prop = ref.watch(_reviewPropertyProvider(widget.propertyId));
    final row = prop.value;
    final fee = row == null
        ? null
        : ref.watch(_feeProvider(row['transaction_type'] as String)).value;

    Widget body;
    if (prop.isLoading && row == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (row == null) {
      body = Center(child: Text(t.authGenericError));
    } else {
      final status = row['publication_status'] as String;
      final canSubmit = status == 'draft' || status == 'rejected';
      final canPay = status == 'pending_payment' ||
          status == 'payment_failed' ||
          status == 'payment_processing';
      body = ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Card(
          child: ListTile(
            title: Text(row['title'] as String),
            subtitle: Text(formatMoney(
                (row['price_amount'] as num).toInt(), (row['price_currency'] as String).trim())),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (fee != null)
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.reviewFeeLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(formatMoney(fee, 'IQD'), style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(t.reviewFeeNote, style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (fee == null && canSubmit)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(t.reviewNoFee),
          ),
        if (canSubmit)
          FilledButton(
            key: const Key('continueToPaymentButton'),
            onPressed: _busy ? null : _submit,
            child: Text(fee == null ? t.reviewSubmit : t.reviewContinue),
          ),
        if (canPay) ...[
          Text(t.payChooseMethod, style: theme.textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: _provider,
            onChanged: (v) => setState(() => _provider = v ?? _provider),
            child: Column(children: [
              RadioListTile<String>(value: 'FIB', title: Text(t.payFib)),
              RadioListTile<String>(value: 'QI_CARD', title: Text(t.payQi)),
            ]),
          ),
          FilledButton(
            key: const Key('payNowButton'),
            onPressed: _busy ? null : _pay,
            child: Text(fee == null ? t.payPayNow : '${t.payPayNow} ${formatMoney(fee, 'IQD')}'),
          ),
          if (_orderId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(t.payOpened, style: theme.textTheme.bodySmall),
            OutlinedButton(
              key: const Key('checkPaymentButton'),
              onPressed: _busy ? null : _check,
              child: Text(t.payCheck),
            ),
          ],
        ],
        if (!canSubmit && !canPay)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(status == 'published' ? t.reviewPublished : t.reviewWaitingApproval),
            ),
          ),
        if (_notConfigured)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(t.payNotConfigured),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(_message!),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.go('/profile/properties'),
          child: Text(t.myPropertiesTitle),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.reviewTitle)),
      body: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: body),
      ),
    );
  }
}
