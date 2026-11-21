import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../../core/network/api_client.dart';

class PropertyImage {
  const PropertyImage({required this.id, required this.path, required this.isCover});
  final String id;
  final String path;
  final bool isCover;
}

class MediaRepository {
  MediaRepository(this._client, this._api);
  final SupabaseClient _client;
  final ApiClient _api;

  Future<List<PropertyImage>> images(String propertyId) async {
    final rows = await _client
        .from('property_images')
        .select('id,storage_path,is_cover,sort_order')
        .eq('property_id', propertyId)
        .isFilter('ai_variant_of', null)
        .order('sort_order');
    return [
      for (final r in rows)
        PropertyImage(
            id: r['id'] as String,
            path: r['storage_path'] as String,
            isCover: r['is_cover'] as bool? ?? false),
    ];
  }

  String publicUrl(String path) =>
      _client.storage.from('property-media').getPublicUrl(path);

  /// 1) server validates + returns a signed upload URL, 2) bytes go straight to
  /// Storage, 3) server re-checks the real file type and registers it.
  Future<void> uploadImage(String propertyId, Uint8List bytes, String contentType) async {
    final signed = await _api.post('/api/v1/media/upload-url', {
      'property_id': propertyId,
      'kind': 'image',
      'content_type': contentType,
      'bytes': bytes.length,
    });
    final path = signed['path'] as String;
    await _client.storage.from('property-media').uploadBinaryToSignedUrl(
          path,
          signed['token'] as String,
          bytes,
          FileOptions(contentType: contentType),
        );
    await _api.post('/api/v1/media/confirm', {
      'property_id': propertyId,
      'kind': 'image',
      'path': path,
    });
  }

  Future<void> delete(PropertyImage image) async {
    await _client.storage.from('property-media').remove([image.path]);
    await _client.from('property_images').delete().eq('id', image.id);
  }
}

final mediaRepositoryProvider = Provider<MediaRepository?>((ref) {
  final api = ref.watch(apiClientProvider);
  if (!Env.isSupabaseConfigured || api == null) return null;
  return MediaRepository(Supabase.instance.client, api);
});

final propertyImagesProvider =
    FutureProvider.family<List<PropertyImage>, String>((ref, id) async =>
        await ref.watch(mediaRepositoryProvider)?.images(id) ?? const []);
