/// Normalizes Iraqi mobile numbers to E.164 (+964 7XX XXX XXXX).
/// Accepts: 07701234567, 7701234567, 009647701234567, +9647701234567,
/// and Arabic-Indic / Persian digits. Returns null when invalid.
String? normalizeIraqiPhone(String input) {
  var s = _toLatinDigits(input).replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.startsWith('+')) s = s.substring(1);
  if (s.startsWith('00')) s = s.substring(2);
  if (s.startsWith('964')) {
    s = s.substring(3);
  }
  if (s.startsWith('0')) s = s.substring(1);
  // Iraqi mobile: 7 followed by 9 digits (75x, 77x, 78x, 79x).
  if (!RegExp(r'^7[3-9]\d{8}$').hasMatch(s)) return null;
  return '+964$s';
}

String _toLatinDigits(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final a = arabic.indexOf(c);
    final p = persian.indexOf(c);
    b.write(a >= 0 ? a : (p >= 0 ? p : c));
  }
  return b.toString();
}

String? normalizeOtp(String input) {
  final s = _toLatinDigits(input).replaceAll(RegExp(r'\s'), '');
  return RegExp(r'^\d{6}$').hasMatch(s) ? s : null;
}
