import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/presentation/property_card_tile.dart';
import '../data/favorites_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(favoritesListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.navFavorites)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
              onPressed: () => ref.invalidate(favoritesListProvider),
              child: Text(t.retry)),
        ),
        data: (items) => items.isEmpty
            ? Center(child: Text(t.favoritesEmpty))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(favoritesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => PropertyCardTile(property: items[i]),
                ),
              ),
      ),
    );
  }
}
