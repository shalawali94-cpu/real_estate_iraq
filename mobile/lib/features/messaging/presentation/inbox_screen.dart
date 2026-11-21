import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/messaging_repository.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final inbox = ref.watch(inboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.messagesTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: inbox.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(kDebugMode ? '$e' : t.authGenericError)),
            data: (list) => list.isEmpty
                ? Center(child: Text(t.messagesEmpty))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(inboxProvider.future),
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          leading: CircleAvatar(
                              child: Text(c.otherName.isEmpty ? '?' : c.otherName[0])),
                          title: Text(c.otherName),
                          subtitle: Text(c.preview ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: c.unread > 0
                              ? Badge(label: Text('${c.unread}'))
                              : null,
                          onTap: () async {
                            await context.push('/chat/${c.id}');
                            ref.invalidate(inboxProvider);
                          },
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
