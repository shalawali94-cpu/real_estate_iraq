import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships no Material/Cupertino/Widgets localizations for Kurdish
/// Sorani (ckb). These delegates serve the Arabic ones for ckb, which gives
/// correct RTL direction and Arabic-script system strings. Must be listed
/// before the global delegates (first supporting delegate per type wins).
class _CkbFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _CkbFallbackDelegate(this._inner);

  final LocalizationsDelegate<T> _inner;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<T> load(Locale locale) => _inner.load(const Locale('ar'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

const List<LocalizationsDelegate<dynamic>> ckbFallbackDelegates = [
  _CkbFallbackDelegate<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  ),
  _CkbFallbackDelegate<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
  _CkbFallbackDelegate<WidgetsLocalizations>(
    GlobalWidgetsLocalizations.delegate,
  ),
];
