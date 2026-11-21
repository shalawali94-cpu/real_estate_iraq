/// Formats integer minor units. IQD has no minor unit (dinars); USD is in cents.
/// Pure integer math: never floating point for money.
String formatMoney(int minorUnits, String currency) {
  final cur = currency.toUpperCase();
  if (cur == 'USD') {
    final whole = minorUnits ~/ 100;
    final cents = minorUnits % 100;
    final w = _group(whole);
    return cents == 0 ? '\$$w' : '\$$w.${cents.toString().padLeft(2, '0')}';
  }
  return '${_group(minorUnits)} $cur';
}

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}
