import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_iraq/app.dart';
import 'package:real_estate_iraq/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const RealEstateIraqApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('defaults to Kurdish Sorani with RTL layout', (tester) async {
    await pumpApp(tester);
    expect(find.text('سەرەکی'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(NavigationBar)));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('English is LTR when saved', (tester) async {
    await pumpApp(tester, prefs: {'app_locale': 'en'});
    expect(find.text('Home'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(NavigationBar)));
    expect(dir, TextDirection.ltr);
  });

  testWidgets('switching language on Profile updates the UI', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('پرۆفایل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
