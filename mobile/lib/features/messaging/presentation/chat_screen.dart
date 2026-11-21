import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void dispose() {
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
        repo?.markRead(widget.conversationId);
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
      appBar: AppBar(title: Text(title)),
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
                            alignment: mine
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
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
