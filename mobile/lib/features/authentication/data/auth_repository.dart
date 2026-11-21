import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';

/// Thin wrapper over Supabase phone OTP auth. All real authorization is
/// enforced by RLS / the backend, never by this client.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String e164Phone) =>
      _client.auth.signInWithOtp(phone: e164Phone);

  Future<void> verifyOtp(String e164Phone, String code) =>
      _client.auth.verifyOTP(phone: e164Phone, token: code, type: OtpType.sms);

  Future<void> signOut() => _client.auth.signOut();
}

/// Null when Supabase isn't configured (tests / missing --dart-define).
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  return AuthRepository(Supabase.instance.client);
});

final sessionProvider = StreamProvider<Session?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) {
    yield null;
    return;
  }
  yield repo.currentSession;
  await for (final s in repo.authChanges) {
    yield s.session;
  }
});
