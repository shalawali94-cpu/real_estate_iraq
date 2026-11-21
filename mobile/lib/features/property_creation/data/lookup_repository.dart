import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';

typedef DbRow = Map<String, dynamic>;

/// Reference data (governorates, districts, categories) is read from Supabase,
/// never hardcoded in the app.
class LookupRepository {
  LookupRepository(this._c);
  final SupabaseClient _c;

  Future<List<DbRow>> governorates() async => List<DbRow>.from(await _c
      .from('governorates')
      .select('id,name_ckb,name_ar,name_en,center_lat,center_lng')
      .eq('is_active', true)
      .order('sort_order'));

  Future<List<DbRow>> districts(int governorateId) async => List<DbRow>.from(await _c
      .from('districts')
      .select('id,name_ckb,name_ar,name_en,center_lat,center_lng')
      .eq('governorate_id', governorateId)
      .eq('is_active', true)
      .order('name_en'));

  Future<List<DbRow>> categories() async => List<DbRow>.from(await _c
      .from('property_categories')
      .select('id,slug,name_ckb,name_ar,name_en,fields,allowed_transaction_types')
      .eq('is_active', true)
      .order('sort_order'));

  /// Returns the new draft id. Insert is validated by RLS + triggers.
  Future<String> createDraft(DbRow values) async {
    final uid = _c.auth.currentUser!.id;
    final row = await _c
        .from('properties')
        .insert({...values, 'owner_id': uid})
        .select('id')
        .single();
    return row['id'] as String;
  }
}

final lookupRepositoryProvider = Provider<LookupRepository?>((ref) =>
    Env.isSupabaseConfigured ? LookupRepository(Supabase.instance.client) : null);

final governoratesProvider = FutureProvider<List<DbRow>>((ref) async =>
    await ref.watch(lookupRepositoryProvider)?.governorates() ?? const []);

final categoriesProvider = FutureProvider<List<DbRow>>((ref) async =>
    await ref.watch(lookupRepositoryProvider)?.categories() ?? const []);

final districtsProvider = FutureProvider.family<List<DbRow>, int>((ref, govId) async =>
    await ref.watch(lookupRepositoryProvider)?.districts(govId) ?? const []);
