import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../compare/presentation/compare_screen.dart';
import '../../map/presentation/property_map_card.dart';

import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../favorites/data/favorites_repository.dart';
import 'report_dialog.dart';
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

final propertyCoordsProvider =
    FutureProvider.family<LatLng?, String>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  if (repo == null) return null;
  final c = await repo.coords(id);
  return c == null ? null : LatLng(c.lat, c.lng);
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
        PopupMenuButton<String>(
          key: const Key('detailMenu'),
          onSelected: (v) {
            if (v == 'report') showReportDialog(context, id);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'report', child: Text(t.reportMenu)),
          ],
        ),
      ]),
      bottomNavigationBar: async.value == null ? null : _ContactBar(d: async.value!),
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

/// Always-visible contact actions at the bottom of the screen.
class _ContactBar extends ConsumerWidget {
  const _ContactBar({required this.d});
  final PropertyDetail d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phone = d.phone;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    key: const Key('messageOwnerButton'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    onPressed: () => _message(context, ref, d.owner.id, d.id),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(t.contactMessage),
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    key: const Key('callButton'),
                    tooltip: t.contactCall,
                    onPressed: () => _open(Uri(scheme: 'tel', path: phone)),
                    icon: const Icon(Icons.call),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    key: const Key('whatsappButton'),
                    tooltip: t.contactWhatsApp,
                    onPressed: () =>
                        _open(Uri.parse('https://wa.me/${phone.replaceAll('+', '')}')),
                    icon: const Icon(Icons.chat_outlined),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls});
  final List<String> urls;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.urls;
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: (c.maxWidth * 3 / 4).clamp(0.0, 340.0).toDouble(),
        child: _content(theme, urls),
      ),
    );
  }

  Widget _content(ThemeData theme, List<String> urls) {
    return Builder(
      builder: (context) => urls.isEmpty
          ? ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.home_work_outlined, size: 64))
          : Stack(fit: StackFit.expand, children: [
              PageView(
                onPageChanged: (i) => setState(() => _i = i),
                children: [
                  for (final u in urls) CachedNetworkImage(imageUrl: u, fit: BoxFit.cover),
                ],
              ),
              if (urls.length > 1)
                PositionedDirectional(
                  bottom: 10,
                  end: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('${_i + 1} / ${urls.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                ),
            ]),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.d});
  final PropertyDetail d;

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
    return ListView(
      children: [
        _Gallery(urls: urls),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              DecoratedBox(
                decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(transactionLabel(t, d.transactionType),
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              if (d.owner.verified) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.verified, size: 20, color: theme.colorScheme.secondary),
              ],
            ]),
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(formatMoney(d.priceAmount, d.priceCurrency),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (d.priceNegotiable) Text(t.negotiable, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(d.title, style: theme.textTheme.titleMedium),
            if (d.addressText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                Icon(Icons.place_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(d.addressText!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              ]),
            ],
            Consumer(builder: (context, ref, _) {
              final inList = ref.watch(compareIdsProvider).contains(d.id);
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: OutlinedButton.icon(
                  key: const Key('compareToggle'),
                  icon: Icon(inList ? Icons.check_circle : Icons.compare_arrows),
                  label: Text(inList ? t.compareRemove : t.compareAdd),
                  onPressed: () {
                    final m = ScaffoldMessenger.of(context);
                    final ok = ref.read(compareIdsProvider.notifier).toggle(d.id);
                    m.hideCurrentSnackBar();
                    if (!ok) {
                      m.showSnackBar(SnackBar(
                          duration: const Duration(seconds: 2), content: Text(t.compareFull)));
                    } else if (ref.read(compareIdsProvider).contains(d.id)) {
                      const w = 170.0;
                      final sw = MediaQuery.of(context).size.width;
                      final side = EdgeInsets.only(
                        left: (sw - w) / 2,
                        right: (sw - w) / 2,
                        bottom: 96,
                      );
                      m.showSnackBar(SnackBar(
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: side,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        content: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xEB0E1621),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8FB4E0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x408FB4E0), blurRadius: 8),
                            ],
                          ),
                          child: Text(t.compareAdded,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ),
                      ));
                    }
                  },
                ),
              );
            }),
            Consumer(builder: (context, ref, _) {
              final p = ref.watch(propertyCoordsProvider(d.id)).value;
              if (p == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: PropertyMapCard(point: p),
              );
            }),
            if (specs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(t.specsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 86,
                ),
                children: [
                  for (final s in specs)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(s.$1, size: 22, color: theme.colorScheme.primary),
                        const SizedBox(height: 4),
                        Text(s.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(s.$2, style: theme.textTheme.labelSmall),
                      ]),
                    ),
                ],
              ),
            ],
            if ((d.description ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(t.descriptionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Text(d.description!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (d.owner.name?.trim().isNotEmpty ?? false)
                          ? d.owner.name!.trim().characters.first
                          : '?',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.ownerTitle, style: theme.textTheme.labelSmall),
                      Text(d.owner.name ?? '—', style: theme.textTheme.titleSmall),
                    ]),
                  ),
                  if (d.owner.verified) Icon(Icons.verified, color: theme.colorScheme.secondary),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${t.views}: ${d.viewsCount}', style: theme.textTheme.bodySmall),
          ]),
        ),
      ],
    );
  }
}

String? conditionLabel(AppLocalizations t, String? v) => _condition(t, v);
String? furnishingLabel(AppLocalizations t, String? v) => _furnishing(t, v);
