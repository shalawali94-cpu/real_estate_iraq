class PropertyOwner {
  const PropertyOwner({required this.id, this.name, this.phone, this.verified = false});
  final String id;
  final String? name;
  final String? phone; // already filtered by the server's show_phone rule
  final bool verified;
}

class PropertyDetail {
  const PropertyDetail({
    required this.id,
    required this.title,
    required this.transactionType,
    required this.priceAmount,
    required this.priceCurrency,
    required this.priceNegotiable,
    required this.imagePaths,
    required this.owner,
    this.description,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.floors,
    this.buildingCondition,
    this.furnishing,
    this.hasParking,
    this.addressText,
    this.contactPhone,
    this.viewsCount = 0,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String transactionType;
  final int priceAmount;
  final String priceCurrency;
  final bool priceNegotiable;
  final num? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final int? floors;
  final String? buildingCondition;
  final String? furnishing;
  final bool? hasParking;
  final String? addressText;
  final String? contactPhone;
  final int viewsCount;
  final DateTime? publishedAt;
  final List<String> imagePaths;
  final PropertyOwner owner;

  /// Number to call: listing contact number if set, else the owner's public number.
  String? get phone => contactPhone ?? owner.phone;

  factory PropertyDetail.fromRow(Map<String, dynamic> j, PropertyOwner owner) {
    final imgs = ((j['property_images'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((i) => i['status'] != 'rejected')
        .toList()
      ..sort((a, b) {
        final c = (b['is_cover'] == true ? 1 : 0) - (a['is_cover'] == true ? 1 : 0);
        return c != 0 ? c : ((a['sort_order'] as num).compareTo(b['sort_order'] as num));
      });
    final showPhone = j['show_phone'] as bool? ?? true;
    return PropertyDetail(
      id: j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String?,
      transactionType: j['transaction_type'] as String,
      priceAmount: (j['price_amount'] as num).toInt(),
      priceCurrency: (j['price_currency'] as String).trim(),
      priceNegotiable: j['price_negotiable'] as bool? ?? false,
      areaSqm: j['area_sqm'] as num?,
      bedrooms: (j['bedrooms'] as num?)?.toInt(),
      bathrooms: (j['bathrooms'] as num?)?.toInt(),
      floors: (j['floors'] as num?)?.toInt(),
      buildingCondition: j['building_condition'] as String?,
      furnishing: j['furnishing'] as String?,
      hasParking: j['has_parking'] as bool?,
      addressText: j['address_text'] as String?,
      contactPhone: showPhone ? j['contact_phone'] as String? : null,
      viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
      publishedAt: j['published_at'] == null ? null : DateTime.parse(j['published_at'] as String),
      imagePaths: [for (final i in imgs) i['storage_path'] as String],
      owner: owner,
    );
  }
}
