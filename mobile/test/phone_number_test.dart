import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_iraq/features/authentication/data/phone_number.dart';

void main() {
  group('normalizeIraqiPhone', () {
    test('accepts common formats', () {
      for (final i in ['07701234567', '7701234567', '+9647701234567', '009647701234567', '0770 123 4567', '964 770-123-4567']) {
        expect(normalizeIraqiPhone(i), '+9647701234567', reason: i);
      }
    });
    test('accepts Arabic-Indic and Persian digits', () {
      expect(normalizeIraqiPhone('٠٧٧٠١٢٣٤٥٦٧'), '+9647701234567');
      expect(normalizeIraqiPhone('۰۷۷۰۱۲۳۴۵۶۷'), '+9647701234567');
    });
    test('rejects invalid', () {
      for (final i in ['', '123', '0770123456', '077012345678', '06701234567', '+9661234567890', 'abc']) {
        expect(normalizeIraqiPhone(i), isNull, reason: i);
      }
    });
  });
  group('normalizeOtp', () {
    test('valid and invalid', () {
      expect(normalizeOtp('123456'), '123456');
      expect(normalizeOtp('١٢٣٤٥٦'), '123456');
      expect(normalizeOtp('12345'), isNull);
      expect(normalizeOtp('12345a'), isNull);
    });
  });
}
