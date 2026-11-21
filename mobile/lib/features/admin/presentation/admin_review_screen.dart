import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../../core/format/money.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../authentication/data/auth_repository.dart';

/// True when the signed-in user holds a staff role. This only decides whether the
/// button is shown; the backend re-checks the role on every admin call.
final isStaffProvider = FutureProvider.autoDispose<bool>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (!Env.isSupabaseConfigured || session == null) return false;
  final rows = await Supabase.instance.client
      .from('user_roles')
      .select('role')
      .eq('user_id', session.user.id);
  const staff = {'moderator', 'admin', 'super_admin'};
  return rows.any((r) => staff.contains(r['role']));
});

class _Item {
  const _Item(this.id, this.title, this.status, this.amount, this.currency,
      this.type, this.cover, this.reason);
  final String id;
  final String title;
  final String status;
  final int amount;
  final String currency;
  final String type;
  final String? cover;
  final String? reason;
}

final _queueProvider =
    FutureProvider.autoDispose.family<List<_Item>, String>((ref, status) async {
  final api = ref.watch(apiClientProvider);
  if (api == null) return const [];
  final res = await api.get('/api/v1/admin/properties?status=$status&limit=50');
  final items = (res['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  return [
    for (final r in items)
      _Item(
        r['id'] as String,
        r['title'] as String,
        r['publication_status'] as String,
        (r['price_amount'] as num).toInt(),
        (r['price_currency'] as String).trim(),
        r['transaction_type'] as String,
        _cover(r['property_images'] as List<dynamic>?),
        r['rejection_reason'] as String?,
      ),
  ];
});

String? _cover(List<dynamic>? imgs) {
  if (imgs == null || imgs.isEmpty) return null;
  final list = imgs.cast<Map<String, dynamic>>().toList()
    ..sort((a, b) {
      final ca = (a['is_cover'] as bool? ?? false) ? 0 : 1;
      final cb = (b['is_cover'] as bool? ?? false) ? 0 : 1;
      if (ca != cb) return ca - cb;
      return ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0);
    });
  return list.first['storage_path'] as String?;
}

const _tabs = ['pending_approval', 'published', 'rejected', 'suspended'];

class AdminReviewScreen extends ConsumerWidget {
  const AdminReviewScreen({super.key});

  String _label(AppLocalizations t, String s) => switch (s) {
        'pending_approval' => t.statusPendingApproval,
        'published' => t.statusPublished,
        'rejected' => t.statusRejected,
        'suspended' => t.adminStatusSuspended,
        _ => s,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.adminReviewTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final s in _tabs) Tab(text: _label(t, s))],
          ),
        ),
        body: TabBarView(
          children: [for (final s in _tabs) _Queue(status: s)],
        ),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({required this.status});
  final String status;

  Future<void> _decide(BuildContext context, WidgetRef ref, _Item p, String decision) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    if (decision == 'reject' || decision == 'suspend') {
      reason = await _askReason(context, t);
      if (reason == null) return; // cancelled
    }
    try {
      await ref.read(apiClientProvider)!.post(
        '/api/v1/admin/properties/${p.id}/moderate',
        {'decision': decision, if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      for (final s in _tabs) {
        ref.invalidate(_queueProvider(s));
      }
      messenger.showSnackBar(SnackBar(content: Text(t.adminDone)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${t.authGenericError} (${e.code})')));
    }
  }

  Future<String?> _askReason(BuildContext context, AppLocalizations t) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminReasonTitle),
        content: TextField(
          controller: c,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(hintText: t.adminReasonHint),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: Text(t.cancel)),
          FilledButton(onPressed: () => ctx.pop(c.text.trim()), child: Text(t.adminConfirm)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final q = ref.watch(_queueProvider(status));
    return q.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(t.authGenericError)),
      data: (list) => list.isEmpty
          ? Center(child: Text(t.adminEmpty))
          : RefreshIndicator(
              onRefresh: () => ref.refresh(_queueProvider(status).future),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final p = list[i];
                  final url = p.cover == null
                      ? null
                      : Supabase.instance.client.storage
                          .from('property-media')
                          .getPublicUrl(p.cover!);
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: url == null
                                  ? const Icon(Icons.home_work_outlined)
                                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text('${formatMoney(p.amount, p.currency)} · ${p.type}'),
                                  if (p.reason != null && p.reason!.isNotEmpty)
                                    Text(p.reason!,
                                        style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(spacing: AppSpacing.sm, children: [
                            OutlinedButton(
                              onPressed: () => context.push('/property/${p.id}'),
                              child: Text(t.adminView),
                            ),
                            if (status == 'pending_approval') ...[
                              FilledButton(
                                key: Key('approve-${p.id}'),
                                onPressed: () => _decide(context, ref, p, 'approve'),
                                child: Text(t.adminApprove),
                              ),
                              OutlinedButton(
                                onPressed: () => _decide(context, ref, p, 'reject'),
                                child: Text(t.adminReject),
                              ),
                            ],
                            if (status == 'published')
                              OutlinedButton(
                                onPressed: () => _decide(context, ref, p, 'suspend'),
                                child: Text(t.adminSuspend),
                              ),
                            if (status == 'suspended')
                              FilledButton(
                                onPressed: () => _decide(context, ref, p, 'unsuspend'),
                                child: Text(t.adminUnsuspend),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
