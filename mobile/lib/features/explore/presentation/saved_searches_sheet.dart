import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// What gets stored in saved_searches.filters: the exact server query plus the
/// UI state needed to restore the Explore screen.
class SavedSearch {
  const SavedSearch(this.id, this.name, this.filters);
  final String id;
  final String name;
  final Map<String, dynamic> filters;
}

final savedSearchesProvider = FutureProvider.autoDispose<List<SavedSearch>>((ref) async {
  final c = Supabase.instance.client;
  if (c.auth.currentUser == null) return const [];
  final rows = await c
      .from('saved_searches')
      .select('id,name,filters')
      .order('created_at', ascending: false);
  return [
    for (final r in rows)
      SavedSearch(r['id'] as String, r['name'] as String,
          Map<String, dynamic>.from(r['filters'] as Map)),
  ];
});

/// Returns the chosen saved search's filters (to apply), or null.
Future<Map<String, dynamic>?> showSavedSearchesSheet(
    BuildContext context, Map<String, dynamic> current) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _Sheet(current: current),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet({required this.current});
  final Map<String, dynamic> current;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.searchSaveCurrent),
        content: TextField(
          controller: c,
          maxLength: 60,
          decoration: InputDecoration(labelText: t.searchName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: Text(t.saveProfile)),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty) return;
    final client = Supabase.instance.client;
    try {
      await client.from('saved_searches').insert({
        'user_id': client.auth.currentUser!.id,
        'name': name,
        'filters': current,
      });
      ref.invalidate(savedSearchesProvider);
      messenger.showSnackBar(SnackBar(content: Text(t.searchSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.authGenericError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final list = ref.watch(savedSearchesProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t.searchesTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: list.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator()),
              error: (e, _) => Text(t.authGenericError),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg), child: Text(t.searchEmpty))
                  : ListView(shrinkWrap: true, children: [
                      for (final s in items)
                        ListTile(
                          title: Text(s.name),
                          onTap: () => Navigator.of(context).pop(s.filters),
                          trailing: IconButton(
                            tooltip: t.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await Supabase.instance.client
                                  .from('saved_searches')
                                  .delete()
                                  .eq('id', s.id);
                              ref.invalidate(savedSearchesProvider);
                            },
                          ),
                        ),
                    ]),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('saveSearchButton'),
            onPressed: () => _save(context, ref),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(t.searchSaveCurrent),
          ),
        ]),
      ),
    );
  }
}
