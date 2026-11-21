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

    // A "typing" change is a track() update, which arrives as join/leave events.
    ch
        .onPresenceSync((_) => recompute())
        .onPresenceJoin((_) => recompute())
        .onPresenceLeave((_) => recompute())
        .subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        ch.track({'user_id': me, 'typing': false});
      }
    });
    _channel = ch;
  }

  void _recomputePresence(RealtimeChannel ch, String me) {
    var online = false;
    var typing = false;
    for (final state in ch.presenceState()) {
      for (final p in state.presences) {
        final d = p.payload;
        if (d['user_id'] != me) {
          online = true;
          if (d['typing'] == true) typing = true;
        }
      }
    }
    if (mounted) {
      setState(() {
        _otherOnline = online;
        _otherTyping = typing;
      });
    }
  }

  Future<void> _markRead() async {
    try {
      await ref.read(messagingRepositoryProvider)?.markRead(widget.conversationId);
    } catch (e) {
      debugPrint('markRead error: $e');
    }
  }

  void _setTyping(bool value) {
    if (_iAmTyping == value) return;
    _iAmTyping = value;
    final repo = ref.read(messagingRepositoryProvider);
    _channel?.track({'user_id': repo?.myId, 'typing': value});
  }

  void _onTextChanged() {
    if (_text.text.trim().isEmpty) {
      _typingTimer?.cancel();
      _setTyping(false);
      return;
    }
    _setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _setTyping(false));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
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
          if (_otherTyping || _otherOnline)
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (!_otherTyping)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
              Text(
                _otherTyping ? t.chatTyping : t.chatOnline,
                style: theme.textTheme.bodySmall,
              ),
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
