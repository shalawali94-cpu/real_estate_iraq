/// Lightweight listing row returned by the search_properties RPC.
class PropertySummary {
  const PropertySummary({
    required this.id,
    required this.title,
    required this.transactionType,
    required this.priceAmount,
    required this.priceCurrency,
    required this.priceNegotiable,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.coverPath,
    this.isFeatured = false,
    this.ownerVerified = false,
  });

  final String id;
  final String title;
  final String transactionType;
  final int priceAmount;
  final String priceCurrency;
  final bool priceNegotiable;
  final num? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final String? coverPath;
  final bool isFeatured;
  final bool ownerVerified;

  factory PropertySummary.fromJson(Map<String, dynamic> j) => PropertySummary(
        id: j['id'] as String,
        title: j['title'] as String,
        transactionType: j['transaction_type'] as String,
        priceAmount: (j['price_amount'] as num).toInt(),
        priceCurrency: (j['price_currency'] as String).trim(),
        priceNegotiable: j['price_negotiable'] as bool? ?? false,
        areaSqm: j['area_sqm'] as num?,
        bedrooms: (j['bedrooms'] as num?)?.toInt(),
        bathrooms: (j['bathrooms'] as num?)?.toInt(),
        coverPath: j['cover_path'] as String?,
        isFeatured: j['is_featured'] as bool? ?? false,
        ownerVerified: (j['owner_identity_verified'] as bool? ?? false) ||
            (j['company_verified'] as bool? ?? false),
      );
}
