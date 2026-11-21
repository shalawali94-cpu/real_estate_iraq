import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../domain/property_detail.dart';
import '../domain/property_summary.dart';

/// Search is always server-side (RPC + pagination); never filter in Flutter.
class PropertyRepository {
  PropertyRepository(this._client);
  final SupabaseClient _client;

  static const pageSize = 20;

  Future<List<PropertySummary>> search({
    Map<String, dynamic> filters = const {},
    int offset = 0,
    int limit = pageSize,
  }) async {
    final rows = await _client.rpc('search_properties', params: {
      'p_filters': filters,
      'p_limit': limit,
      'p_offset': offset,
    }) as List<dynamic>;
    return rows
        .map((r) => PropertySummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyDetail?> detail(String id) async {
    final row = await _client
        .from('properties')
        .select('*, property_images(storage_path,is_cover,sort_order,status)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final ownerId = row['owner_id'] as String;
    final profiles = await _client
        .rpc('get_public_profiles', params: {'p_ids': [ownerId]}) as List<dynamic>;
    final pr = profiles.isEmpty ? null : profiles.first as Map<String, dynamic>;
    final owner = PropertyOwner(
      id: ownerId,
      name: pr?['full_name'] as String?,
      phone: pr?['phone'] as String?,
      verified: (pr?['identity_verified'] as bool? ?? false),
    );
    return PropertyDetail.fromRow(row, owner);
  }

  /// Counts a view (server dedupes). Failures are non-fatal.
  Future<void> recordView(String id) async {
    try {
      await _client.rpc('record_property_view', params: {'p_property': id});
    } catch (_) {}
  }

  String? publicUrl(String path) => _client.storage.from('property-media').getPublicUrl(path);

  String? coverUrl(String? storagePath) => storagePath == null
      ? null
      : _client.storage.from('property-media').getPublicUrl(storagePath);
}

final propertyRepositoryProvider = Provider<PropertyRepository?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  return PropertyRepository(Supabase.instance.client);
});
