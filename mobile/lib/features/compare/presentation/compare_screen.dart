import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/property_detail.dart';
import '../../properties/presentation/property_card.dart' show transactionLabel;
import '../../properties/presentation/property_detail_screen.dart'
    show conditionLabel, furnishingLabel;

const maxCompare = 5;

class CompareController extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// Returns false when the list is full and [id] was not added.
  bool toggle(String id) {
    if (state.contains(id)) {
      state = [for (final x in state) if (x != id) x];
      return true;
    }
    if (state.length >= maxCompare) return false;
    state = [...state, id];
    return true;
  }

  void remove(String id) => state = [for (final x in state) if (x != id) x];
  void clear() => state = const [];
}

final compareIdsProvider =
    NotifierProvider<CompareController, List<String>>(CompareController.new);

// Plain fetch (no view counting) for comparison.
final _compareItemProvider = FutureProvider.family<PropertyDetail?, String>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo?.detail(id);
});

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final ids = ref.watch(compareIdsProvider);
    final repo = ref.watch(propertyRepositoryProvider);
    final items = <PropertyDetail>[];
    var loading = false;
    for (final id in ids) {
      final a = ref.watch(_compareItemProvider(id));
      if (a.isLoading) loading = true;
      if (a.value != null) items.add(a.value!);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.compareTitle),
        actions: [
          if (ids.isNotEmpty)
            TextButton(
                onPressed: () => ref.read(compareIdsProvider.notifier).clear(),
                child: Text(t.compareClear)),
        ],
      ),
      body: ids.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(t.compareEmpty, textAlign: TextAlign.center),
              ),
            )
          : loading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _Table(items: items, repo: repo),
    );
  }
}

class _Table extends ConsumerWidget {
  const _Table({required this.items, required this.repo});
  final List<PropertyDetail> items;
  final PropertyRepository? repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const colW = 150.0;

    final rows = <(String, List<String?>)>[
      (t.fieldPrice, [for (final d in items) formatMoney(d.priceAmount, d.priceCurrency)]),
      (t.fieldTransaction, [for (final d in items) transactionLabel(t, d.transactionType)]),
      (t.specArea, [for (final d in items) d.areaSqm == null ? null : '${d.areaSqm} ${t.sqm}']),
      (t.specBedrooms, [for (final d in items) d.bedrooms?.toString()]),
      (t.specBathrooms, [for (final d in items) d.bathrooms?.toString()]),
      (t.specFloors, [for (final d in items) d.floors?.toString()]),
      (t.specCondition, [for (final d in items) conditionLabel(t, d.buildingCondition)]),
      (t.specFurnishing, [for (final d in items) furnishingLabel(t, d.furnishing)]),
      (t.specParking, [for (final d in items) d.hasParking == null ? null : (d.hasParking! ? t.yes : t.no)]),
      (t.fieldAddress, [for (final d in items) d.addressText]),
    ];

    // The best value on price (lowest) and area (largest) is highlighted when comparable.
    int? bestPrice;
    if (items.length > 1 && items.every((d) => d.priceCurrency == items.first.priceCurrency)) {
      bestPrice = 0;
      for (var i = 1; i < items.length; i++) {
        if (items[i].priceAmount < items[bestPrice!].priceAmount) bestPrice = i;
      }
    }

    Widget cell(Widget child, {bool highlight = false}) => Container(
          width: colW,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlight ? theme.colorScheme.primaryContainer.withValues(alpha: .5) : null,
            border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .4))),
          ),
          child: child,
        );

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final d in items)
              SizedBox(
                width: colW,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
                    onTap: () => context.push('/property/${d.id}'),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: d.imagePaths.isEmpty || repo?.publicUrl(d.imagePaths.first) == null
                                ? ColoredBox(color: theme.colorScheme.surfaceContainerHigh)
                                : CachedNetworkImage(
                                    imageUrl: repo!.publicUrl(d.imagePaths.first)!,
                                    fit: BoxFit.cover),
                          ),
                        ),
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: IconButton.filledTonal(
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ref.read(compareIdsProvider.notifier).remove(d.id),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(d.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall),
                    ]),
                  ),
                ),
              ),
          ]),
          for (final r in rows)
            if (r.$2.any((v) => v != null))
              Row(children: [
                for (var i = 0; i < items.length; i++)
                  cell(
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.$1,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(r.$2[i] ?? '—',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                    highlight: r.$1 == t.fieldPrice && bestPrice == i,
                  ),
              ]),
        ]),
      ),
    );
  }
}
