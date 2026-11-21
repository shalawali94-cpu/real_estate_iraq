import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../favorites/data/favorites_repository.dart';
import '../data/property_repository.dart';
import '../domain/property_summary.dart';
import 'property_card.dart';

/// Card wired to image URLs, favorites and navigation to the details page.
class PropertyCardTile extends ConsumerWidget {
  const PropertyCardTile({super.key, required this.property});
  final PropertySummary property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(propertyRepositoryProvider);
    final signedIn = ref.watch(favoritesRepositoryProvider) != null;
    final favs = ref.watch(favoriteIdsProvider);
    return PropertyCard(
      property: property,
      imageUrl: repo?.coverUrl(property.coverPath),
      isFavorite: signedIn ? favs.contains(property.id) : false,
      onFavorite: () {
        if (!signedIn) {
          final from = GoRouterState.of(context).uri.toString();
          context.push('/login?from=${Uri.encodeComponent(from)}');
          return;
        }
        ref.read(favoriteIdsProvider.notifier).toggle(property.id);
      },
      onTap: () => context.push('/property/${property.id}'),
    );
  }
}
