import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';

class MyProperty {
  const MyProperty(this.id, this.title, this.status, this.amount, this.currency, this.coverPath);
  final String id;
  final String title;
  final String status;
  final int amount;
  final String currency;
  final String? coverPath;
}

/// The signed-in user's own listings (RLS returns only their rows), any status.
final myPropertiesProvider = FutureProvider<List<MyProperty>>((ref) async {
  if (!Env.isSupabaseConfigured) return const [];
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  if (uid == null) return const [];
  final rows = await c
      .from('properties')
      .select('id,title,publication_status,price_amount,price_currency,created_at,'
          'property_images(storage_path,is_cover,sort_order)')
      .eq('owner_id', uid)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false);
  return [
    for (final r in rows)
      MyProperty(
        r['id'] as String,
        r['title'] as String,
        r['publication_status'] as String,
        (r['price_amount'] as num).toInt(),
        (r['price_currency'] as String).trim(),
        _cover(r['property_images'] as List<dynamic>?),
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

String _statusLabel(AppLocalizations t, String s) => switch (s) {
      'draft' => t.statusDraft,
      'pending_payment' => t.statusPendingPayment,
      'pending_approval' => t.statusPendingApproval,
      'published' => t.statusPublished,
      'rejected' => t.statusRejected,
      _ => s,
    };

class MyPropertiesScreen extends ConsumerWidget {
  const MyPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final items = ref.watch(myPropertiesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.myPropertiesTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(t.authGenericError)),
            data: (list) => list.isEmpty
                ? Center(child: Text(t.myPropertiesEmpty))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(myPropertiesProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final url = p.coverPath == null
                            ? null
                            : Supabase.instance.client.storage
                                .from('property-media')
                                .getPublicUrl(p.coverPath!);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: SizedBox(
                              width: 64,
                              height: 64,
                              child: url == null
                                  ? const Icon(Icons.home_work_outlined)
                                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                            ),
                            title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${formatMoney(p.amount, p.currency)} · ${_statusLabel(t, p.status)}'),
                            onTap: () => context.push(p.status == 'published'
                                ? '/property/${p.id}'
                                : '/draft/${p.id}/media'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
