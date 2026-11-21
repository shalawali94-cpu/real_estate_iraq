import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_name.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../property_creation/data/lookup_repository.dart';

/// Filters chosen in the sheet (everything except the search text and the
/// transaction-type chips). Prices are kept as whole units the user typed;
/// they are converted to integer minor units only when the query is built.
class ExploreFilters {
  const ExploreFilters({
    this.categoryId,
    this.governorateId,
    this.districtId,
    this.currency = 'IQD',
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.sort = 'newest',
  });
  final int? categoryId;
  final int? governorateId;
  final int? districtId;
  final String currency;
  final int? minPrice;
  final int? maxPrice;
  final int? minBedrooms;
  final String sort;

  int get activeCount => [
        categoryId,
        governorateId,
        districtId,
        minPrice,
        maxPrice,
        minBedrooms,
        sort == 'newest' ? null : sort,
      ].where((e) => e != null).length;

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'governorate_id': governorateId,
        'district_id': districtId,
        'currency': currency,
        'min_price': minPrice,
        'max_price': maxPrice,
        'min_bedrooms': minBedrooms,
        'sort': sort,
      };

  factory ExploreFilters.fromJson(Map<String, dynamic> j) => ExploreFilters(
        categoryId: (j['category_id'] as num?)?.toInt(),
        governorateId: (j['governorate_id'] as num?)?.toInt(),
        districtId: (j['district_id'] as num?)?.toInt(),
        currency: (j['currency'] as String?) == 'USD' ? 'USD' : 'IQD',
        minPrice: (j['min_price'] as num?)?.toInt(),
        maxPrice: (j['max_price'] as num?)?.toInt(),
        minBedrooms: (j['min_bedrooms'] as num?)?.toInt(),
        sort: (j['sort'] as String?) ?? 'newest',
      );

  Map<String, dynamic> toQuery() {
    final factor = currency == 'USD' ? 100 : 1; // integer minor units, no floats
    return {
      'category_id': ?categoryId,
      'governorate_id': ?governorateId,
      'district_id': ?districtId,
      if (minPrice != null || maxPrice != null) 'currency': currency,
      if (minPrice != null) 'min_price': minPrice! * factor,
      if (maxPrice != null) 'max_price': maxPrice! * factor,
      'min_bedrooms': ?minBedrooms,
      if (sort != 'newest') 'sort': sort,
    };
  }
}

Future<ExploreFilters?> showFilterSheet(BuildContext context, ExploreFilters current) {
  return showModalBottomSheet<ExploreFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final ExploreFilters initial;
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late int? _category = widget.initial.categoryId;
  late int? _gov = widget.initial.governorateId;
  late int? _district = widget.initial.districtId;
  late String _currency = widget.initial.currency;
  late int? _beds = widget.initial.minBedrooms;
  late String _sort = widget.initial.sort;
  late final _min = TextEditingController(text: widget.initial.minPrice?.toString() ?? '');
  late final _max = TextEditingController(text: widget.initial.maxPrice?.toString() ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _num(TextEditingController c) => int.tryParse(c.text.trim());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final govs = ref.watch(governoratesProvider).value ?? const [];
    final dists = _gov == null
        ? const <DbRow>[]
        : (ref.watch(districtsProvider(_gov!)).value ?? const <DbRow>[]);
    final sorts = {
      'newest': t.sortNewest,
      'price_asc': t.sortPriceAsc,
      'price_desc': t.sortPriceDesc,
      'area_desc': t.sortArea,
      'popular': t.sortPopular,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            DropdownButtonFormField<int?>(
              key: ValueKey('cat$_category'),
              initialValue: _category,
              decoration: InputDecoration(labelText: t.fieldCategory),
              items: [
                DropdownMenuItem(value: null, child: Text(t.filterAll)),
                for (final c in cats)
                  DropdownMenuItem(value: c['id'] as int, child: Text(localizedName(context, c))),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int?>(
              key: ValueKey('gov$_gov'),
              initialValue: _gov,
              decoration: InputDecoration(labelText: t.fieldGovernorate),
              items: [
                DropdownMenuItem(value: null, child: Text(t.filterAll)),
                for (final g in govs)
                  DropdownMenuItem(value: g['id'] as int, child: Text(localizedName(context, g))),
              ],
              onChanged: (v) => setState(() {
                _gov = v;
                _district = null;
              }),
            ),
            if (_gov != null) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                key: ValueKey('dist$_gov$_district'),
                initialValue: _district,
                decoration: InputDecoration(labelText: t.fieldDistrict),
                items: [
                  DropdownMenuItem(value: null, child: Text(t.filterAll)),
                  for (final d in dists)
                    DropdownMenuItem(value: d['id'] as int, child: Text(localizedName(context, d))),
                ],
                onChanged: (v) => setState(() => _district = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.filterMinPrice),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t.filterMaxPrice),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'IQD', label: Text('IQD')),
                  ButtonSegment(value: 'USD', label: Text('USD')),
                ],
                selected: {_currency},
                onSelectionChanged: (s) => setState(() => _currency = s.first),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(t.filterMinBedrooms, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, children: [
              for (final n in [null, 1, 2, 3, 4, 5])
                ChoiceChip(
                  label: Text(n == null ? t.filterAll : '$n+'),
                  selected: _beds == n,
                  onSelected: (_) => setState(() => _beds = n),
                ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(t.filterSort, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, children: [
              for (final e in sorts.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _sort == e.key,
                  onSelected: (_) => setState(() => _sort = e.key),
                ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(const ExploreFilters()),
                  child: Text(t.filterReset),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const Key('applyFiltersButton'),
                  onPressed: () => Navigator.of(context).pop(ExploreFilters(
                    categoryId: _category,
                    governorateId: _gov,
                    districtId: _district,
                    currency: _currency,
                    minPrice: _num(_min),
                    maxPrice: _num(_max),
                    minBedrooms: _beds,
                    sort: _sort,
                  )),
                  child: Text(t.filterApply),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
