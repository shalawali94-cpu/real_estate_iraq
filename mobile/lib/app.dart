import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';
import 'localization/app_settings_controllers.dart';
import 'localization/ckb_fallback_delegates.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class RealEstateIraqApp extends ConsumerWidget {
  const RealEstateIraqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      routerConfig: ref.watch(appRouterProvider),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...ckbFallbackDelegates, // must come first
        ...AppLocalizations.localizationsDelegates,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
    );
  }
}
