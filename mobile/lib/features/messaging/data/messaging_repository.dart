import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../authentication/data/auth_repository.dart';

class ConversationItem {
  const ConversationItem({
    required this.id,
    required this.otherName,
    required this.preview,
    required this.lastAt,
    required this.unread,
  });
  final String id;
  final String otherName;
  final String? preview;
  final DateTime? lastAt;
  final int unread;
}

class ChatMessage {
  const ChatMessage(this.id, this.senderId, this.body, this.createdAt);
  final String id;
  final String senderId;
  final String? body;
  final DateTime createdAt;
}

/// All access is through Supabase with RLS: a user only ever sees conversations
/// they are a member of, and can only send into those (and not when blocked).
class MessagingRepository {
  MessagingRepository(this._c);
  final SupabaseClient _c;

  String get myId => _c.auth.currentUser!.id;

  /// Opens (or reuses) a conversation with the listing's owner. Server validates it.
  Future<String> open(String otherUserId, {String? propertyId}) async {
    final id = await _c.rpc('conversation_open', params: {
      'p_other': otherUserId,
      'p_property': ?propertyId,
    });
    return id as String;
  }

  Future<List<ConversationItem>> inbox() async {
    final mine = await _c
        .from('conversation_members')
        .select('unread_count, conversations(id,last_message_at,last_message_preview)')
        .eq('user_id', myId);
    if (mine.isEmpty) return const [];
    final ids = [for (final r in mine) (r['conversations'] as Map)['id'] as String];
    final members = await _c
        .from('conversation_members')
        .select('conversation_id,user_id')
        .inFilter('conversation_id', ids)
        .neq('user_id', myId);
    final otherByConv = {
      for (final m in members) m['conversation_id'] as String: m['user_id'] as String,
    };
    final List<dynamic> profiles = otherByConv.isEmpty
        ? const []
        : await _c.rpc('get_public_profiles',
            params: {'p_ids': otherByConv.values.toSet().toList()});
    final names = {for (final p in profiles) p['id'] as String: p['full_name'] as String?};
    final items = [
      for (final r in mine)
        () {
          final c = r['conversations'] as Map<String, dynamic>;
          final id = c['id'] as String;
          final last = c['last_message_at'] as String?;
          return ConversationItem(
            id: id,
            otherName: names[otherByConv[id]] ?? '—',
            preview: c['last_message_preview'] as String?,
            lastAt: last == null ? null : DateTime.parse(last).toLocal(),
            unread: (r['unread_count'] as num?)?.toInt() ?? 0,
          );
        }(),
    ]..sort((a, b) => (b.lastAt ?? DateTime(2000)).compareTo(a.lastAt ?? DateTime(2000)));
    return items;
  }

  Future<String> otherName(String conversationId) async {
    final m = await _c
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId)
        .neq('user_id', myId)
        .maybeSingle();
    if (m == null) return '';
    final List<dynamic> p =
        await _c.rpc('get_public_profiles', params: {'p_ids': [m['user_id'] as String]});
    return p.isEmpty ? '' : ((p.first as Map)['full_name'] as String?) ?? '';
  }

  ChatMessage _toMessage(Map<String, dynamic> r) => ChatMessage(
      r['id'] as String,
      r['sender_id'] as String,
      r['body'] as String?,
      DateTime.parse(r['created_at'] as String).toLocal());

  /// Messages, oldest first: a normal query first (so the screen never waits on the
  /// websocket), then live updates from Supabase Realtime.
  Stream<List<ChatMessage>> messages(String conversationId) async* {
    final first = await _c
        .from('messages')
        .select('id,sender_id,body,created_at')
        .eq('conversation_id', conversationId)
        .isFilter('deleted_at', null)
        .order('created_at');
    yield _sorted([for (final r in first) _toMessage(r)]);
    yield* _c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => _sorted([
              for (final r in rows)
                if (r['deleted_at'] == null) _toMessage(r),
            ]));
  }

  /// Always oldest first, whatever order the server or realtime delivers.
  List<ChatMessage> _sorted(List<ChatMessage> l) =>
      l..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> send(String conversationId, String body) => _c.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': myId,
        'body': body,
      });

  Future<void> markRead(String conversationId) =>
      _c.rpc('conversation_mark_read', params: {'p_conv': conversationId});
}

final messagingRepositoryProvider = Provider<MessagingRepository?>((ref) {
  ref.watch(sessionProvider); // rebuild on sign-in / sign-out
  return Env.isSupabaseConfigured && Supabase.instance.client.auth.currentUser != null
      ? MessagingRepository(Supabase.instance.client)
      : null;
});

final inboxProvider = FutureProvider.autoDispose<List<ConversationItem>>(
    (ref) async => await ref.watch(messagingRepositoryProvider)?.inbox() ?? const []);

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
    (ref, id) => ref.watch(messagingRepositoryProvider)?.messages(id) ?? Stream.value(const []));

final chatTitleProvider = FutureProvider.autoDispose.family<String, String>(
    (ref, id) async => await ref.watch(messagingRepositoryProvider)?.otherName(id) ?? '');
