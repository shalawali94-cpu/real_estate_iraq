import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/data/auth_repository.dart';
import '../../properties/domain/property_summary.dart';

class FavoritesRepository {
  FavoritesRepository(this._client);
  final SupabaseClient _client;
  String get _uid => _client.auth.currentUser!.id;

  Future<Set<String>> ids() async {
    final rows = await _client.from('property_favorites').select('property_id');
    return {for (final r in rows) r['property_id'] as String};
  }

  Future<void> add(String propertyId) => _client
      .from('property_favorites')
      .upsert({'user_id': _uid, 'property_id': propertyId});

  Future<void> remove(String propertyId) => _client
      .from('property_favorites')
      .delete()
      .eq('user_id', _uid)
      .eq('property_id', propertyId);

  Future<List<PropertySummary>> list() async {
    final rows = await _client
        .from('property_favorites')
        .select('created_at, properties(*, property_images(storage_path,is_cover,sort_order,status))')
        .order('created_at', ascending: false);
    final out = <PropertySummary>[];
    for (final r in rows) {
      final p = r['properties'] as Map<String, dynamic>?;
      if (p == null) continue; // listing no longer visible (RLS)
      final imgs = ((p['property_images'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .where((i) => i['status'] != 'rejected')
          .toList()
        ..sort((a, b) {
          final c = (b['is_cover'] == true ? 1 : 0) - (a['is_cover'] == true ? 1 : 0);
          return c != 0 ? c : ((a['sort_order'] as num).compareTo(b['sort_order'] as num));
        });
      out.add(PropertySummary.fromJson({
        ...p,
        'cover_path': imgs.isEmpty ? null : imgs.first['storage_path'],
      }));
    }
    return out;
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository?>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return null;
  return FavoritesRepository(Supabase.instance.client);
});

/// Set of favorited property ids with optimistic toggling.
class FavoriteIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final repo = ref.watch(favoritesRepositoryProvider);
    if (repo != null) {
      repo.ids().then((v) => state = v).catchError((_) => state);
    }
    return const {};
  }

  Future<void> toggle(String id) async {
    final repo = ref.read(favoritesRepositoryProvider);
    if (repo == null) return;
    final was = state.contains(id);
    state = was ? ({...state}..remove(id)) : {...state, id};
    try {
      was ? await repo.remove(id) : await repo.add(id);
      ref.invalidate(favoritesListProvider);
    } catch (_) {
      state = was ? {...state, id} : ({...state}..remove(id)); // roll back
    }
  }
}

final favoriteIdsProvider =
    NotifierProvider<FavoriteIdsController, Set<String>>(FavoriteIdsController.new);

final favoritesListProvider = FutureProvider<List<PropertySummary>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  if (repo == null) return const [];
  return repo.list();
});
