import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/property_summary.dart';
import '../../properties/presentation/property_card_tile.dart';
import '../../properties/presentation/property_list_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final repo = ref.watch(propertyRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredPropertiesProvider);
          ref.invalidate(latestPropertiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Section(title: t.homeFeatured, provider: featuredPropertiesProvider, repo: repo, hideWhenEmpty: true),
            _Section(title: t.homeLatest, provider: latestPropertiesProvider, repo: repo),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.title, required this.provider, required this.repo, this.hideWhenEmpty = false});
  final String title;
  final FutureProvider<List<PropertySummary>> provider;
  final PropertyRepository? repo;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [
          Text(t.authGenericError),
          TextButton(onPressed: () => ref.invalidate(provider), child: Text(t.retry)),
        ]),
      ),
      data: (items) {
        if (items.isEmpty) {
          if (hideWhenEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: Text(t.emptyProperties)),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final p in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PropertyCardTile(property: p),
            ),
        ]);
      },
    );
  }
}
