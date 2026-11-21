import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../messaging/data/messaging_repository.dart';
import '../data/property_repository.dart';
import '../domain/property_detail.dart';
import 'property_card.dart' show transactionLabel;

final propertyDetailProvider =
    FutureProvider.family<PropertyDetail?, String>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  if (repo == null) return null;
  final d = await repo.detail(id);
  if (d != null) repo.recordView(id);
  return d;
});

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(propertyDetailProvider(id));
    final signedIn = ref.watch(favoritesRepositoryProvider) != null;
    final isFav = ref.watch(favoriteIdsProvider).contains(id);
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          onPressed: () {
            if (!signedIn) {
              final from = GoRouterState.of(context).uri.toString();
              context.push('/login?from=${Uri.encodeComponent(from)}');
              return;
            }
            ref.read(favoriteIdsProvider.notifier).toggle(id);
          },
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : null),
        ),
      ]),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t.authGenericError),
            TextButton(
                onPressed: () => ref.invalidate(propertyDetailProvider(id)),
                child: Text(t.retry)),
          ]),
        ),
        data: (d) => d == null
            ? Center(child: Text(t.notFound))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _Body(d: d),
                ),
              ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.d});
  final PropertyDetail d;

  String? _condition(AppLocalizations t, String? v) => switch (v) {
        'new' => t.condNew,
        'excellent' => t.condExcellent,
        'good' => t.condGood,
        'needs_renovation' => t.condNeedsRenovation,
        'under_construction' => t.condUnderConstruction,
        _ => null,
      };

  String? _furnishing(AppLocalizations t, String? v) => switch (v) {
        'unfurnished' => t.furnUnfurnished,
        'semi_furnished' => t.furnSemi,
        'furnished' => t.furnFurnished,
        _ => null,
      };

  Future<void> _message(
      BuildContext context, WidgetRef ref, String ownerId, String propertyId) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final from = GoRouterState.of(context).uri.toString();
    final repo = ref.read(messagingRepositoryProvider);
    if (repo == null) {
      router.push('/login?from=${Uri.encodeComponent(from)}');
      return;
    }
    if (ownerId == repo.myId) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatOwnListing)));
      return;
    }
    try {
      final id = await repo.open(ownerId, propertyId: propertyId);
      router.push('/chat/$id');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.chatOpenFailed)));
    }
  }

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.watch(propertyRepositoryProvider);
    final urls = [for (final p in d.imagePaths) repo!.publicUrl(p)!];
    final specs = <(IconData, String, String)>[
      if (d.bedrooms != null) (Icons.bed_outlined, t.specBedrooms, '${d.bedrooms}'),
      if (d.bathrooms != null) (Icons.bathtub_outlined, t.specBathrooms, '${d.bathrooms}'),
      if (d.areaSqm != null) (Icons.square_foot, t.specArea, '${d.areaSqm} ${t.sqm}'),
      if (d.floors != null) (Icons.layers_outlined, t.specFloors, '${d.floors}'),
      if (_condition(t, d.buildingCondition) != null)
        (Icons.build_outlined, t.specCondition, _condition(t, d.buildingCondition)!),
      if (_furnishing(t, d.furnishing) != null)
        (Icons.chair_outlined, t.specFurnishing, _furnishing(t, d.furnishing)!),
      if (d.hasParking != null)
        (Icons.local_parking, t.specParking, d.hasParking! ? t.yes : t.no),
    ];
    final phone = d.phone;
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: urls.isEmpty
              ? ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.home_work_outlined, size: 64))
              : PageView(children: [
                  for (final u in urls)
                    CachedNetworkImage(imageUrl: u, fit: BoxFit.cover),
                ]),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transactionLabel(t, d.transactionType),
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: AppSpacing.xs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(formatMoney(d.priceAmount, d.priceCurrency),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (d.priceNegotiable) Text(t.negotiable, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(d.title, style: theme.textTheme.titleLarge),
            if (d.addressText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text(d.addressText!)),
              ]),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (specs.isNotEmpty) ...[
              Text(t.specsTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final s in specs)
                  Chip(avatar: Icon(s.$1, size: 18), label: Text('${s.$2}: ${s.$3}')),
              ]),
              const SizedBox(height: AppSpacing.lg),
            ],
            if ((d.description ?? '').isNotEmpty) ...[
              Text(t.descriptionTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(d.description!),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('${t.views}: ${d.viewsCount}', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.ownerTitle, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(children: [
                    Expanded(
                      child: Text(d.owner.name ?? '—', style: theme.textTheme.titleMedium),
                    ),
                    if (d.owner.verified)
                      Icon(Icons.verified, color: theme.colorScheme.secondary),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      key: const Key('messageOwnerButton'),
                      onPressed: () => _message(context, ref, d.owner.id, d.id),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(t.contactMessage),
                    ),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('callButton'),
                          onPressed: () => _open(Uri(scheme: 'tel', path: phone)),
                          icon: const Icon(Icons.call),
                          label: Text(t.contactCall),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('whatsappButton'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52)),
                          onPressed: () => _open(
                              Uri.parse('https://wa.me/${phone.replaceAll('+', '')}')),
                          icon: const Icon(Icons.chat_outlined),
                          label: Text(t.contactWhatsApp),
                        ),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
