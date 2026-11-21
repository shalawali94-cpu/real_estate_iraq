import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_iraq/core/format/money.dart';

void main() {
  test('IQD whole dinars with grouping', () {
    expect(formatMoney(30000, 'IQD'), '30,000 IQD');
    expect(formatMoney(250000000, 'iqd'), '250,000,000 IQD');
    expect(formatMoney(500, 'IQD'), '500 IQD');
  });
  test('USD cents', () {
    expect(formatMoney(10000000, 'USD'), r'$100,000');
    expect(formatMoney(12345, 'USD'), r'$123.45');
    expect(formatMoney(5, 'USD'), r'$0.05');
  });
}
