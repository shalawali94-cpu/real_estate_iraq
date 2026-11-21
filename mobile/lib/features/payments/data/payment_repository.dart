import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env.dart';
import '../../../core/network/api_client.dart';

/// Talks to the backend payment endpoints. Prices and statuses always come from the
/// server; the app never decides that something is paid.
class PaymentRepository {
  PaymentRepository(this._api, this._db);
  final ApiClient _api;
  final SupabaseClient _db;

  /// Publishing fee in IQD (public read of payment_settings).
  /// Returns null when no fee applies to this transaction type (e.g. rentals by default).
  Future<int?> publishingFee(String transactionType) async {
    final row = await _db
        .from('payment_settings')
        .select('price_amount,is_enabled,applies_to_transaction_types')
        .eq('service_type', 'PROPERTY_PUBLISHING')
        .maybeSingle();
    if (row == null || row['is_enabled'] != true) return null;
    final types = (row['applies_to_transaction_types'] as List<dynamic>).cast<String>();
    if (!types.contains(transactionType)) return null;
    return (row['price_amount'] as num).toInt();
  }

  /// draft/rejected -> pending_payment (fee due) or pending_approval (no fee).
  Future<Map<String, dynamic>> submit(String propertyId) =>
      _api.post('/api/v1/properties/$propertyId/submit', const {});

  Future<Map<String, dynamic>> createOrder({
    required String propertyId,
    required String provider, // FIB | QI_CARD
    required String locale,
  }) =>
      _api.post(
        '/api/v1/payments/orders',
        {
          'service_type': 'PROPERTY_PUBLISHING',
          'property_id': propertyId,
          'provider': provider,
          'locale': locale,
        },
        headers: {'Idempotency-Key': _newKey()},
      );

  Future<Map<String, dynamic>> orderStatus(String orderId) =>
      _api.get('/api/v1/payments/orders/$orderId');

  String _newKey() {
    final r = Random.secure();
    final tail = List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
    return 'pub-${DateTime.now().millisecondsSinceEpoch}-$tail';
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository?>((ref) {
  final api = ref.watch(apiClientProvider);
  if (!Env.isSupabaseConfigured || api == null) return null;
  return PaymentRepository(api, Supabase.instance.client);
});
