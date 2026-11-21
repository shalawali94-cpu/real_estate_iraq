import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/property_repository.dart';
import '../domain/property_summary.dart';

class PropertyListState {
  const PropertyListState({
    this.items = const [],
    this.filters = const {},
    this.loading = false,
    this.hasMore = true,
    this.error,
  });
  final List<PropertySummary> items;
  final Map<String, dynamic> filters;
  final bool loading;
  final bool hasMore;
  final Object? error;

  PropertyListState copyWith({
    List<PropertySummary>? items,
    Map<String, dynamic>? filters,
    bool? loading,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      PropertyListState(
        items: items ?? this.items,
        filters: filters ?? this.filters,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Server-side paginated search used by Explore.
class PropertyListController extends Notifier<PropertyListState> {
  int _generation = 0;

  @override
  PropertyListState build() {
    Future.microtask(loadMore);
    return const PropertyListState();
  }

  Future<void> setFilters(Map<String, dynamic> filters) async {
    _generation++;
    state = PropertyListState(filters: filters);
    await loadMore();
  }

  Future<void> loadMore() async {
    final repo = ref.read(propertyRepositoryProvider);
    if (repo == null || state.loading || !state.hasMore) return;
    final gen = _generation;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await repo.search(
          filters: state.filters, offset: state.items.length);
      if (gen != _generation) return; // filters changed meanwhile
      state = state.copyWith(
        items: [...state.items, ...page],
        loading: false,
        hasMore: page.length == PropertyRepository.pageSize,
      );
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(loading: false, error: e);
    }
  }
}

final exploreListProvider =
    NotifierProvider<PropertyListController, PropertyListState>(
        PropertyListController.new);

/// Home sections.
final featuredPropertiesProvider = FutureProvider<List<PropertySummary>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  if (repo == null) return const [];
  return repo.search(filters: {'featured': true}, limit: 10);
});

final latestPropertiesProvider = FutureProvider<List<PropertySummary>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  if (repo == null) return const [];
  return repo.search(filters: {'sort': 'newest'}, limit: 10);
});
