import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/messaging_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  int _lastCount = 0;

  // Presence (Supabase Realtime): who has this chat open, and who is typing.
  RealtimeChannel? _channel;
  Timer? _typingTimer;
  Timer? _otherTypingExpiry;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  bool _iAmTyping = false;
  bool _otherOnline = false;
  bool _otherTyping = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinPresence();
      _markRead();
    });
  }

  void _joinPresence() {
    final repo = ref.read(messagingRepositoryProvider);
    if (repo == null || !mounted) return;
    final me = repo.myId;
    final ch = Supabase.instance.client.channel('chat:${widget.conversationId}');
    void recompute() {
      try {
        _recomputePresence(ch, me);
      } catch (e) {
        debugPrint('presence error: $e');
      }
    }

    // Online = present in this channel. Typing = short-lived broadcast events.
    ch
        .onPresenceSync((_) => recompute())
        .onPresenceJoin((_) => recompute())
        .onPresenceLeave((_) => recompute())
        .onBroadcast(event: 'typing', callback: (payload) {
          final d = (payload['payload'] is Map)
              ? (payload['payload'] as Map).cast<String, dynamic>()
              : payload;
          if (d['user_id'] == me) return;
          _otherTypingExpiry?.cancel();
          final typing = d['typing'] == true;
          if (mounted) setState(() => _otherTyping = typing);
          if (typing) {
            // Safety net if the "stopped typing" event is lost.
            _otherTypingExpiry = Timer(const Duration(seconds: 5), () {
              if (mounted) setState(() => _otherTyping = false);
            });
          }
        })
        .subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        ch.track({'user_id': me});
      }
    });
    _channel = ch;
  }

  void _recomputePresence(RealtimeChannel ch, String me) {
    var online = false;
    for (final state in ch.presenceState()) {
      for (final p in state.presences) {
        if (p.payload['user_id'] != me) online = true;
      }
    }
    if (mounted) setState(() => _otherOnline = online);
  }

  Future<void> _markRead() async {
    try {
      await ref.read(messagingRepositoryProvider)?.markRead(widget.conversationId);
    } catch (e) {
      debugPrint('markRead error: $e');
    }
  }

  void _setTyping(bool value) {
    final repo = ref.read(messagingRepositoryProvider);
    if (_iAmTyping == value && value == false) return;
    _iAmTyping = value;
    _lastTypingSent = DateTime.now();
    _channel?.sendBroadcastMessage(
        event: 'typing', payload: {'user_id': repo?.myId, 'typing': value});
  }

  void _onTextChanged() {
    if (_text.text.trim().isEmpty) {
      _typingTimer?.cancel();
      _setTyping(false);
      return;
    }
    // Re-announce every 2 seconds while typing.
    if (!_iAmTyping || DateTime.now().difference(_lastTypingSent).inSeconds >= 2) {
      _setTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _setTyping(false));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _otherTypingExpiry?.cancel();
    final ch = _channel;
    if (ch != null) Supabase.instance.client.removeChannel(ch);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    final repo = ref.read(messagingRepositoryProvider);
    if (body.isEmpty || repo == null || _sending) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await repo.send(widget.conversationId, body);
      _text.clear();
      _setTyping(false);
    } catch (e) {
      debugPrint('send error: $e');
      messenger.showSnackBar(SnackBar(content: Text(kDebugMode ? '$e' : t.chatSendFailed)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.watch(messagingRepositoryProvider);
    final title = ref.watch(chatTitleProvider(widget.conversationId)).value ?? '';
    final msgs = ref.watch(chatMessagesProvider(widget.conversationId));

    ref.listen(chatMessagesProvider(widget.conversationId), (_, next) {
      final list = next.value;
      if (list == null) return;
      if (list.length != _lastCount) {
        final first = _lastCount == 0;
        _lastCount = list.length;
        _markRead();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          final end = _scroll.position.maxScrollExtent;
          if (first) {
            _scroll.jumpTo(end);
          } else {
            _scroll.animateTo(end,
                duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title),
          if (_otherOnline)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsetsDirectional.only(end: 6),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              Text(t.chatOnline, style: theme.textTheme.bodySmall),
            ]),
        ]),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            Expanded(
              child: msgs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(kDebugMode ? '$e' : t.authGenericError)),
                data: (list) => list.isEmpty
                    ? Center(child: Text(t.chatEmpty))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final m = list[i];
                          final mine = m.senderId == repo?.myId;
                          return Align(
                            // Physical sides, independent of language direction (like
                            // Messenger/Instagram): my messages right, theirs left.
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 440),
                              decoration: BoxDecoration(
                                color: mine
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(m.body ?? ''),
                            ),
                          );
                        },
                      ),
              ),
            ),
            // "typing…" sits right above the message box, like Messenger.
            if (_otherTyping)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Text(t.chatTyping,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chatInput'),
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: t.chatHint),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    key: const Key('chatSendButton'),
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
