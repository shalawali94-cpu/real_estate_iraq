import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/presentation/property_card_tile.dart';
import '../../properties/presentation/property_list_controller.dart';
import 'filter_sheet.dart';
import 'saved_searches_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String? _tx;
  ExploreFilters _filters = const ExploreFilters();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        ref.read(exploreListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(exploreListProvider.notifier).setFilters(_currentQuery());
  }

  Future<void> _openSaved() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      context.push('/login?from=${Uri.encodeComponent('/explore')}');
      return;
    }
    final current = {
      ..._currentQuery(),
      'ui': {..._filters.toJson(), 'q': _search.text.trim(), 'tx': _tx},
    };
    final picked = await showSavedSearchesSheet(context, current);
    if (picked == null || !mounted) return;
    final ui = Map<String, dynamic>.from((picked['ui'] as Map?) ?? const {});
    setState(() {
      _filters = ExploreFilters.fromJson(ui);
      _tx = ui['tx'] as String?;
      _search.text = (ui['q'] as String?) ?? '';
    });
    _apply();
  }

  Map<String, dynamic> _currentQuery() {
    final q = _search.text.trim();
    return {
      if (q.isNotEmpty) 'q': q,
      if (_tx != null) 'transaction_type': _tx,
      ..._filters.toQuery(),
    };
  }

  Future<void> _openFilters() async {
    final res = await showFilterSheet(context, _filters);
    if (res == null || !mounted) return;
    setState(() => _filters = res);
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(exploreListProvider);
    final types = {
      null: t.filterAll,
      'sale': t.txSale,
      'rent': t.txRent,
      'short_term_rent': t.txShortTermRent,
      'investment': t.txInvestment,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(t.navExplore),
        actions: [
          IconButton(
            key: const Key('savedSearchesButton'),
            tooltip: t.searchesTitle,
            onPressed: _openSaved,
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          IconButton(
            key: const Key('filterButton'),
            tooltip: t.filterTitle,
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _filters.activeCount > 0,
              label: Text('${_filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: TextField(
            key: const Key('exploreSearch'),
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(),
            decoration: InputDecoration(
              hintText: t.exploreSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _search.clear();
                  _apply();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              for (final e in types.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _tx == e.key,
                    onSelected: (_) {
                      setState(() => _tx = e.key);
                      _apply();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: state.items.isEmpty && !state.loading
              ? Center(
                  child: state.error != null
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(t.authGenericError),
                          TextButton(
                              onPressed: () => ref.read(exploreListProvider.notifier).loadMore(),
                              child: Text(t.retry)),
                        ])
                      : Text(t.emptyProperties))
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.items.length + (state.loading ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    if (i >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final p = state.items[i];
                    return PropertyCardTile(property: p);
                  },
                ),
        ),
      ]),
    );
  }
}
