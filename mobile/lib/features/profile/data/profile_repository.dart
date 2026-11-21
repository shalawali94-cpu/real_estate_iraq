import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../authentication/data/auth_repository.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    required this.accountType,
    this.governorateId,
    this.districtId,
    required this.onboarded,
    required this.roles,
  });
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String accountType;
  final int? governorateId;
  final int? districtId;
  final bool onboarded;
  final Set<String> roles;

  bool get isStaff =>
      roles.any((r) => const {'moderator', 'admin', 'super_admin'}.contains(r));

  /// Highest role to show as a badge; null for ordinary members.
  String? get topRole {
    for (final r in const ['super_admin', 'admin', 'moderator']) {
      if (roles.contains(r)) return r;
    }
    return null;
  }
}

/// Reads/updates the signed-in user's own profile. Roles are read-only here:
/// they can only be granted server-side.
class ProfileRepository {
  ProfileRepository(this._c);
  final SupabaseClient _c;

  Future<UserProfile?> load() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final p = await _c
        .from('profiles')
        .select('id,full_name,phone,email,account_type,governorate_id,district_id,onboarded_at')
        .eq('id', uid)
        .maybeSingle();
    if (p == null) return null;
    final roles = await _c.from('user_roles').select('role').eq('user_id', uid);
    return UserProfile(
      id: uid,
      fullName: p['full_name'] as String?,
      phone: p['phone'] as String?,
      email: p['email'] as String?,
      accountType: p['account_type'] as String? ?? 'individual',
      governorateId: (p['governorate_id'] as num?)?.toInt(),
      districtId: (p['district_id'] as num?)?.toInt(),
      onboarded: p['onboarded_at'] != null,
      roles: {for (final r in roles) r['role'] as String},
    );
  }

  Future<void> save({
    required String fullName,
    required String email,
    required String accountType,
    int? governorateId,
    int? districtId,
    required bool markOnboarded,
  }) async {
    await _c.from('profiles').update({
      'full_name': fullName,
      'email': email,
      'account_type': accountType,
      'governorate_id': governorateId,
      'district_id': districtId,
      if (markOnboarded) 'onboarded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', _c.auth.currentUser!.id);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  if (ref.watch(sessionProvider).value == null) return null;
  return ProfileRepository(Supabase.instance.client);
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo?.load();
});
