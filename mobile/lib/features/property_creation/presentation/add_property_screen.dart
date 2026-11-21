import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localized_name.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/presentation/property_card.dart' show transactionLabel;
import '../data/lookup_repository.dart';

/// Step 1 of the publishing wizard: listing details, saved as a DRAFT.
/// Media upload and the 30,000 IQD payment steps follow in later units.
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

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (_category == null || _tx == null || _gov == null || _district == null) {
      setState(() {}); // dropdown validators show errors
      return;
    }
    setState(() => _busy = true);
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
        if (_has('area_sqm') && area.isNotEmpty) 'area_sqm': num.parse(area),
        if (_has('bedrooms') && _beds.text.isNotEmpty) 'bedrooms': _intOrNull(_beds),
        if (_has('bathrooms') && _baths.text.isNotEmpty) 'bathrooms': _intOrNull(_baths),
        if (_has('floors') && _floors.text.isNotEmpty) 'floors': _intOrNull(_floors),
        if (_has('building_condition') && _condition != null) 'building_condition': _condition,
        if (_has('furnishing') && _furnishing != null) 'furnishing': _furnishing,
        if (_has('has_parking') && _parking != null) 'has_parking': _parking,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.draftSaved)));
      context.push('/draft/$draftId/media');
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
                if (_category != null) ...[
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
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('saveDraftButton'),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.saveDraft),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
            ),
          ),
        ),
      ),
    );
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

  Widget _gap(Widget w) =>
      Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: w);
}
