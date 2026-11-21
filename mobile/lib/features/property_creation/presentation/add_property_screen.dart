import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/localized_name.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/presentation/property_card.dart' show transactionLabel;
import '../data/lookup_repository.dart';
import '../data/media_repository.dart';

/// Publishing wizard step 1: property type, photos, then details.
/// Photos stay on the device until the final save; only then are the draft created
/// and the photos uploaded. The 30,000 IQD payment step follows in a later unit.
class _LocalPhoto {
  _LocalPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});
  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();
  final _beds = TextEditingController();
  final _baths = TextEditingController();
  final _floors = TextEditingController();
  final _address = TextEditingController();
  LatLng? _point;

  DbRow? _category;
  String? _tx;
  String _currency = 'IQD';
  bool _negotiable = false;
  int? _gov;
  int? _district;
  String? _condition;
  String? _furnishing;
  bool? _parking;
  bool _busy = false;
  static const _maxPhotos = 20;
  final List<_LocalPhoto> _photos = [];
  int _cover = 0;
  bool _photoError = false;
  int _uploaded = 0;

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _area, _beds, _baths, _floors, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _has(String field) =>
      (_category?['fields'] as List<dynamic>?)?.contains(field) ?? false;

  List<String> get _allowedTx =>
      ((_category?['allowed_transaction_types'] as List<dynamic>?) ?? const [])
          .cast<String>();

  /// Money is converted with integer math only (USD dollars -> cents).
  int _minorUnits(String digits) {
    final n = int.parse(digits);
    return _currency == 'USD' ? n * 100 : n;
  }

  int? _intOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : int.parse(c.text.trim());

  String _contentType(XFile f) {
    final m = f.mimeType;
    if (m != null && m.startsWith('image/')) return m;
    final n = f.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pickPhotos() async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    final picker = ImagePicker();
    final List<XFile> files;
    if (room == 1) {
      final one = await picker.pickImage(source: ImageSource.gallery);
      files = one == null ? const [] : [one];
    } else {
      files = await picker.pickMultiImage(limit: room);
    }
    if (files.isEmpty) return;
    final added = <_LocalPhoto>[];
    for (final f in files.take(room)) {
      added.add(_LocalPhoto(await f.readAsBytes(), _contentType(f)));
    }
    if (!mounted) return;
    setState(() {
      _photos.addAll(added);
      _photoError = false;
    });
  }

  void _removePhoto(int i) => setState(() {
        _photos.removeAt(i);
        if (i < _cover) {
          _cover--;
        } else if (i == _cover) {
          _cover = 0;
        }
      });

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final formOk = _form.currentState!.validate();
    if (_photos.isEmpty) setState(() => _photoError = true);
    if (!formOk || _photos.isEmpty) return;
    if (_category == null || _tx == null || _gov == null || _district == null) {
      setState(() {}); // dropdown validators show errors
      return;
    }
    final media = ref.read(mediaRepositoryProvider);
    if (media == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.mediaApiMissing)));
      return;
    }
    setState(() {
      _busy = true;
      _uploaded = 0;
    });
    try {
      final area = _area.text.trim();
      final draftId = await ref.read(lookupRepositoryProvider)!.createDraft({
        'category_id': _category!['id'],
        'transaction_type': _tx,
        'title': _title.text.trim(),
        if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
        'price_amount': _minorUnits(_price.text.trim()),
        'price_currency': _currency,
        'price_negotiable': _negotiable,
        'governorate_id': _gov,
        'district_id': _district,
        if (_address.text.trim().isNotEmpty) 'address_text': _address.text.trim(),
        if (_point != null) 'location': 'SRID=4326;POINT(${_point!.longitude} ${_point!.latitude})',
        if (_has('area_sqm') && area.isNotEmpty) 'area_sqm': num.parse(area),
        if (_has('bedrooms') && _beds.text.isNotEmpty) 'bedrooms': _intOrNull(_beds),
        if (_has('bathrooms') && _baths.text.isNotEmpty) 'bathrooms': _intOrNull(_baths),
        if (_has('floors') && _floors.text.isNotEmpty) 'floors': _intOrNull(_floors),
        if (_has('building_condition') && _condition != null) 'building_condition': _condition,
        if (_has('furnishing') && _furnishing != null) 'furnishing': _furnishing,
        if (_has('has_parking') && _parking != null) 'has_parking': _parking,
      });
      // The chosen cover is uploaded first, which makes it the cover (sort order 0).
      final ordered = [
        _photos[_cover],
        for (var i = 0; i < _photos.length; i++)
          if (i != _cover) _photos[i],
      ];
      var failed = false;
      for (final p in ordered) {
        try {
          await media.uploadImage(draftId, p.bytes, p.contentType);
        } catch (e) {
          debugPrint('upload error: $e');
          failed = true;
        }
        if (!mounted) return;
        setState(() => _uploaded++);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failed ? t.mediaFailed : t.draftSaved)));
      context.go('/draft/$draftId/review');
    } catch (e) {
      debugPrint('createDraft error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                duration: const Duration(seconds: 12),
                content: Text(kDebugMode ? '$e' : t.authGenericError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _digits(String? v, {bool required = false}) {
    final t = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return required ? t.validationRequired : null;
    return RegExp(r'^\d{1,12}$').hasMatch(v.trim()) ? null : t.validationNumber;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cats = ref.watch(categoriesProvider);
    final govs = ref.watch(governoratesProvider);
    final districts = _gov == null ? null : ref.watch(districtsProvider(_gov!));
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(title: Text(t.addPropertyTitle)),
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 3,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: FilledButton(
                  key: const Key('saveDraftButton'),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? Text(_uploaded > 0 || _photos.isNotEmpty
                          ? t.mediaUploading(
                              (_uploaded + 1).clamp(1, _photos.length), _photos.length)
                          : '...')
                      : Text(t.saveDraft),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            // Not a lazy ListView: off-screen fields must stay mounted so Form.validate()
            // checks every field.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _gap(Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _photoSection(t),
                  ),
                )),
                _gap(_section(t.secBasics, [
                _gap(DropdownButtonFormField<DbRow>(
                  key: const Key('categoryField'),
                  decoration: InputDecoration(labelText: t.fieldCategory),
                  initialValue: _category,
                  items: [
                    for (final c in cats.value ?? const <DbRow>[])
                      DropdownMenuItem(value: c, child: Text(localizedName(context, c))),
                  ],
                  validator: (v) => v == null ? t.validationRequired : null,
                  onChanged: (v) => setState(() {
                    _category = v;
                    if (!_allowedTx.contains(_tx)) _tx = null;
                  }),
                )),
                _gap(DropdownButtonFormField<String>(
                  key: ValueKey('tx-${_category?['id']}'),
                  decoration: InputDecoration(labelText: t.fieldTransaction),
                  initialValue: _tx,
                  items: [
                    for (final x in _allowedTx)
                      DropdownMenuItem(value: x, child: Text(transactionLabel(t, x))),
                  ],
                  validator: (v) => v == null ? t.validationRequired : null,
                  onChanged: (v) => setState(() => _tx = v),
                )),
                _gap(TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: t.fieldTitle),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    return (s.length < 5 || s.length > 120) ? t.validationTitleLen : null;
                  },
                )),
                _gap(TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  maxLength: 5000,
                  decoration: InputDecoration(labelText: t.fieldDescription),
                )),
                ])),
                _gap(_section(t.secPrice, [
                _gap(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextFormField(
                        key: const Key('priceField'),
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly,
                        decoration: InputDecoration(labelText: t.fieldPrice),
                        validator: (v) {
                          final e = _digits(v, required: true);
                          if (e != null) return e;
                          return int.parse(v!.trim()) > 0 ? null : t.validationNumber;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(labelText: t.fieldCurrency),
                      items: const [
                        DropdownMenuItem(value: 'IQD', child: Text('IQD')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ])),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.fieldNegotiable),
                  value: _negotiable,
                  onChanged: (v) => setState(() => _negotiable = v),
                ),
                ])),
                _gap(_section(t.secLocation, [
                _gap(DropdownButtonFormField<int>(
                  key: const Key('governorateField'),
                  decoration: InputDecoration(labelText: t.fieldGovernorate),
                  initialValue: _gov,
                  items: [
                    for (final g in govs.value ?? const <DbRow>[])
                      DropdownMenuItem(
                          value: g['id'] as int, child: Text(localizedName(context, g))),
                  ],
                  validator: (v) => v == null ? t.validationRequired : null,
                  onChanged: (v) => setState(() {
                    _gov = v;
                    _district = null;
                  }),
                )),
                _gap(DropdownButtonFormField<int>(
                  key: ValueKey('district-$_gov'),
                  decoration: InputDecoration(labelText: t.fieldDistrict),
                  initialValue: _district,
                  items: [
                    for (final d in districts?.value ?? const <DbRow>[])
                      DropdownMenuItem(
                          value: d['id'] as int, child: Text(localizedName(context, d))),
                  ],
                  validator: (v) => v == null ? t.validationRequired : null,
                  onChanged: (v) => setState(() => _district = v),
                )),
                _gap(TextFormField(
                  controller: _address,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: t.fieldAddress),
                )),
                _gap(OutlinedButton.icon(
                  key: const Key('pickLocationButton'),
                  icon: Icon(_point == null ? Icons.map_outlined : Icons.check_circle,
                      color: _point == null ? null : Colors.green),
                  label: Text(_point == null ? t.setOnMap : t.locationSet),
                  onPressed: () async {
                    final gov = (ref.read(governoratesProvider).value ?? const <DbRow>[])
                        .where((g) => g['id'] == _gov);
                    final dis = (districts?.value ?? const <DbRow>[])
                        .where((d) => d['id'] == _district);
                    LatLng? center;
                    var zoom = 13;
                    for (final e in [(dis, 13), (gov, 9)]) {
                      for (final r in e.$1) {
                        if (center == null &&
                            r['center_lat'] != null &&
                            r['center_lng'] != null) {
                          center = LatLng((r['center_lat'] as num).toDouble(),
                              (r['center_lng'] as num).toDouble());
                          zoom = e.$2;
                        }
                      }
                    }
                    final p = await context.push<LatLng>('/pick-location?z=${_point != null ? 16 : zoom}',
                        extra: _point ?? center);
                    if (p != null) setState(() => _point = p);
                  },
                )),
                ])),
                if (_category != null)
                  _gap(_section(t.secDetails, [
                  if (_has('area_sqm'))
                    _gap(_numField(_area, t.fieldArea, decimal: true)),
                  if (_has('bedrooms')) _gap(_numField(_beds, t.fieldBedrooms)),
                  if (_has('bathrooms')) _gap(_numField(_baths, t.fieldBathrooms)),
                  if (_has('floors')) _gap(_numField(_floors, t.fieldFloors)),
                  if (_has('building_condition'))
                    _gap(DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: t.specCondition),
                      initialValue: _condition,
                      items: [
                        DropdownMenuItem(value: 'new', child: Text(t.condNew)),
                        DropdownMenuItem(value: 'excellent', child: Text(t.condExcellent)),
                        DropdownMenuItem(value: 'good', child: Text(t.condGood)),
                        DropdownMenuItem(value: 'needs_renovation', child: Text(t.condNeedsRenovation)),
                        DropdownMenuItem(value: 'under_construction', child: Text(t.condUnderConstruction)),
                      ],
                      onChanged: (v) => setState(() => _condition = v),
                    )),
                  if (_has('furnishing'))
                    _gap(DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: t.specFurnishing),
                      initialValue: _furnishing,
                      items: [
                        DropdownMenuItem(value: 'unfurnished', child: Text(t.furnUnfurnished)),
                        DropdownMenuItem(value: 'semi_furnished', child: Text(t.furnSemi)),
                        DropdownMenuItem(value: 'furnished', child: Text(t.furnFurnished)),
                      ],
                      onChanged: (v) => setState(() => _furnishing = v),
                    )),
                  if (_has('has_parking'))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.specParking),
                      value: _parking ?? false,
                      onChanged: (v) => setState(() => _parking = v),
                    ),
                  ])),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoSection(AppLocalizations t) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t.photosSectionTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      if (_photos.length > 1) Text(t.photosCoverHint, style: theme.textTheme.bodySmall),
      const SizedBox(height: AppSpacing.sm),
      if (_photos.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemCount: _photos.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: _busy ? null : () => setState(() => _cover = i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                Image.memory(_photos[i].bytes, fit: BoxFit.cover),
                if (i == _cover)
                  PositionedDirectional(
                    bottom: 4,
                    start: 4,
                    child: Chip(
                        label: Text(t.mediaCover), visualDensity: VisualDensity.compact),
                  ),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: IconButton(
                    tooltip: t.mediaDelete,
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _busy ? null : () => _removePhoto(i),
                  ),
                ),
              ]),
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        key: const Key('addPhotosButton'),
        onPressed: (_busy || _photos.length >= _maxPhotos) ? null : _pickPhotos,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text('${t.mediaAdd} (${_photos.length}/$_maxPhotos)'),
      ),
      if (_photoError)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(t.photosRequired,
              style: TextStyle(color: theme.colorScheme.error)),
        ),
    ]);
  }

  Widget _numField(TextEditingController c, String label, {bool decimal = false}) =>
      TextFormField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
        ],
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          return num.tryParse(v.trim()) == null
              ? AppLocalizations.of(context).validationNumber
              : null;
        },
      );

  Widget _section(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ]),
      ),
    );
  }

  Widget _gap(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: w);
}
