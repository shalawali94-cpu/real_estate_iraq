import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
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

  String? coverUrl(String? storagePath) => storagePath == null
      ? null
      : _client.storage.from('property-media').getPublicUrl(storagePath);
}

final propertyRepositoryProvider = Provider<PropertyRepository?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  return PropertyRepository(Supabase.instance.client);
});
