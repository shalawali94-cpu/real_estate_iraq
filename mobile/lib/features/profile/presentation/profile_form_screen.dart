import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localized_name.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../property_creation/data/lookup_repository.dart';
import '../data/profile_repository.dart';

/// First-login onboarding (editMode = false) and later profile editing.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, required this.editMode});
  final bool editMode;
  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _type = 'individual';
  int? _gov;
  int? _district;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _seed(UserProfile? p) {
    if (_seeded || p == null) return;
    _seeded = true;
    _name.text = p.fullName ?? '';
    _type = p.accountType;
    _gov = p.governorateId;
    _district = p.districtId;
  }

  Future<void> _save(UserProfile? current) async {
    final t = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider)!.save(
            fullName: _name.text.trim(),
            accountType: _type,
            governorateId: _gov,
            districtId: _gov == null ? null : _district,
            markOnboarded: current?.onboarded != true,
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.profileSaved)));
      if (widget.editMode && context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(kDebugMode ? '$e' : t.authGenericError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    _seed(profile.value);
    final govs = ref.watch(governoratesProvider);
    final districts = _gov == null ? null : ref.watch(districtsProvider(_gov!));
    final types = {
      'individual': t.accountIndividual,
      'owner': t.accountOwner,
      'agent': t.accountAgent,
      'company': t.accountCompany,
      'developer': t.accountDeveloper,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? t.editProfile : t.onboardingTitle),
        automaticallyImplyLeading: widget.editMode,
      ),
      body: profile.isLoading && !_seeded
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextFormField(
                        key: const Key('fullNameField'),
                        controller: _name,
                        decoration: InputDecoration(labelText: t.fieldFullName),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          return (s.length < 2 || s.length > 80) ? t.validationName : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: InputDecoration(labelText: t.fieldAccountType),
                        items: [
                          for (final e in types.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        initialValue: _gov,
                        decoration: InputDecoration(labelText: t.fieldGovernorateOptional),
                        items: [
                          for (final g in govs.value ?? const <DbRow>[])
                            DropdownMenuItem(
                                value: g['id'] as int, child: Text(localizedName(context, g))),
                        ],
                        onChanged: (v) => setState(() {
                          _gov = v;
                          _district = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        key: ValueKey('pd-$_gov'),
                        initialValue: _district,
                        decoration: InputDecoration(labelText: t.fieldDistrictOptional),
                        items: [
                          for (final d in districts?.value ?? const <DbRow>[])
                            DropdownMenuItem(
                                value: d['id'] as int, child: Text(localizedName(context, d))),
                        ],
                        onChanged: (v) => setState(() => _district = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('saveProfileButton'),
                        onPressed: _busy ? null : () => _save(profile.value),
                        child: _busy
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(t.saveProfile),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}
