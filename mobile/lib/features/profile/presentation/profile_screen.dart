import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../localization/app_settings_controllers.dart';
import '../../../theme/app_theme.dart';

/// Phase 2: language + appearance settings (working).
/// Account sections are added in Phase 5.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final languages = {
      'ckb': t.languageKurdish,
      'ar': t.languageArabic,
      'en': t.languageEnglish,
    };

    return Scaffold(
      appBar: AppBar(title: Text(t.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(t.settingsLanguage, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            key: const Key('languageSelector'),
            segments: [
              for (final e in languages.entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(Locale(s.first)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.settingsTheme, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) => ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(s.first),
          ),
        ],
      ),
    );
  }
}
