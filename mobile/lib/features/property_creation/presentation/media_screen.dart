import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/media_repository.dart';

/// Step 2 of the publishing wizard: property photos (max 20).
class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key, required this.propertyId});
  final String propertyId;
  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen> {
  static const _max = 20;
  int _done = 0;
  int _total = 0;
  bool _failed = false;

  bool get _uploading => _total > _done;

  String _contentType(XFile f) {
    final m = f.mimeType;
    if (m != null && m.startsWith('image/')) return m;
    final n = f.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pick(int existing) async {
    final repo = ref.read(mediaRepositoryProvider);
    if (repo == null) return;
    final files = await ImagePicker().pickMultiImage(limit: _max - existing);
    if (files.isEmpty) return;
    final room = _max - existing;
    final chosen = files.take(room).toList();
    setState(() {
      _done = 0;
      _total = chosen.length;
      _failed = false;
    });
    for (final f in chosen) {
      try {
        await repo.uploadImage(widget.propertyId, await f.readAsBytes(), _contentType(f));
      } catch (e) {
        debugPrint('upload error: $e');
        _failed = true;
      }
      if (!mounted) return;
      setState(() => _done++);
      ref.invalidate(propertyImagesProvider(widget.propertyId));
    }
    if (mounted) setState(() => _total = _done = 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final repo = ref.watch(mediaRepositoryProvider);
    final images = ref.watch(propertyImagesProvider(widget.propertyId));
    final list = images.value ?? const <PropertyImage>[];
    return Scaffold(
      appBar: AppBar(title: Text(t.mediaTitle)),
      body: repo == null
          ? Center(child: Text(t.mediaApiMissing))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(children: [
                  if (_uploading)
                    LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(children: [
                      FilledButton.icon(
                        key: const Key('addPhotosButton'),
                        onPressed: (_uploading || list.length >= _max)
                            ? null
                            : () => _pick(list.length),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(_uploading
                            ? t.mediaUploading(_done + 1, _total)
                            : t.mediaAdd),
                      ),
                      if (list.length >= _max) Text(t.mediaLimit),
                      if (_failed)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(t.mediaFailed,
                              style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                    ]),
                  ),
                  Expanded(
                    child: list.isEmpty && !images.isLoading
                        ? Center(child: Text(t.mediaEmpty, textAlign: TextAlign.center))
                        : GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: AppSpacing.sm,
                              crossAxisSpacing: AppSpacing.sm,
                            ),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final img = list[i];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(fit: StackFit.expand, children: [
                                  CachedNetworkImage(
                                      imageUrl: repo.publicUrl(img.path), fit: BoxFit.cover),
                                  if (img.isCover)
                                    PositionedDirectional(
                                      bottom: 4,
                                      start: 4,
                                      child: Chip(
                                        label: Text(t.mediaCover),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  PositionedDirectional(
                                    top: 0,
                                    end: 0,
                                    child: IconButton(
                                      tooltip: t.mediaDelete,
                                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                                      onPressed: _uploading
                                          ? null
                                          : () async {
                                              await repo.delete(img);
                                              ref.invalidate(
                                                  propertyImagesProvider(widget.propertyId));
                                            },
                                    ),
                                  ),
                                ]),
                              );
                            },
                          ),
                  ),
                ]),
              ),
            ),
    );
  }
}
