import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../authentication/data/auth_repository.dart';

class _Notif {
  const _Notif(this.id, this.type, this.params, this.data, this.read, this.createdAt);
  final String id;
  final String type;
  final Map<String, dynamic> params;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
}

final _notificationsProvider = FutureProvider.autoDispose<List<_Notif>>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (!Env.isSupabaseConfigured || session == null) return const [];
  final rows = await Supabase.instance.client
      .from('notifications')
      .select('id,type,params,data,read_at,created_at')
      .eq('user_id', session.user.id)
      .order('created_at', ascending: false)
      .limit(100);
  return [
    for (final r in rows)
      _Notif(
        r['id'] as String,
        r['type'] as String,
        Map<String, dynamic>.from(r['params'] as Map? ?? const {}),
        Map<String, dynamic>.from(r['data'] as Map? ?? const {}),
        r['read_at'] != null,
        DateTime.parse(r['created_at'] as String).toLocal(),
      ),
  ];
});

/// Unread count for the badge on the profile button.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(_notificationsProvider.future);
  return list.where((n) => !n.read).length;
});

String _title(AppLocalizations t, String type) => switch (type) {
      'new_message' => t.notifNewMessage,
      'property_approved' => t.notifPropertyApproved,
      'property_rejected' => t.notifPropertyRejected,
      'property_suspended' => t.notifPropertySuspended,
      'property_restored' => t.notifPropertyRestored,
      'property_expired' => t.notifPropertyExpired,
      'payment_success' => t.notifPaymentSuccess,
      'payment_failed' => t.notifPaymentFailed,
      'ai_video_completed' => t.notifAiVideoDone,
      'ai_video_failed' => t.notifAiVideoFailed,
      _ => type,
    };

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', uid)
        .isFilter('read_at', null);
    ref.invalidate(_notificationsProvider);
  }

  Future<void> _open(BuildContext context, WidgetRef ref, _Notif n) async {
    if (!n.read) {
      await Supabase.instance.client
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', n.id);
      ref.invalidate(_notificationsProvider);
    }
    if (!context.mounted) return;
    final conv = n.data['conversation_id'] as String?;
    final prop = n.data['property_id'] as String?;
    if (conv != null) {
      context.push('/chat/$conv');
    } else if (prop != null && n.type != 'property_expired') {
      context.push(n.type == 'property_approved' || n.type == 'property_restored'
          ? '/property/$prop'
          : '/draft/$prop/review');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final items = ref.watch(_notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifTitle),
        actions: [
          TextButton(onPressed: () => _markAllRead(ref), child: Text(t.notifMarkAllRead)),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(t.authGenericError)),
        data: (list) => list.isEmpty
            ? Center(child: Text(t.notifEmpty))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(_notificationsProvider.future),
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    final sub = (n.params['preview'] ?? n.params['title'] ?? '').toString();
                    return ListTile(
                      leading: Icon(n.read ? Icons.notifications_none : Icons.notifications_active),
                      title: Text(_title(t, n.type),
                          style: TextStyle(
                              fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                      subtitle: sub.isEmpty ? null : Text(sub, maxLines: 2),
                      trailing: Text(
                        '${n.createdAt.day}/${n.createdAt.month} '
                        '${n.createdAt.hour.toString().padLeft(2, '0')}:'
                        '${n.createdAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => _open(context, ref, n),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
