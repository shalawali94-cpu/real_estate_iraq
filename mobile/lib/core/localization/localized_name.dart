import 'package:flutter/widgets.dart';

/// Picks the Kurdish / Arabic / English column for the active locale.
String localizedName(BuildContext context, Map<String, dynamic> row) {
  final code = Localizations.localeOf(context).languageCode;
  final v = switch (code) {
    'ckb' => row['name_ckb'],
    'ar' => row['name_ar'],
    _ => row['name_en'],
  };
  return (v as String?) ?? (row['name_en'] as String? ?? '');
}
