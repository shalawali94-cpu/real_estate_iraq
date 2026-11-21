import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
          children: [
            _SearchBar(hint: t.exploreSearchHint, onTap: () => context.go('/explore')),
            const SizedBox(height: AppSpacing.sm),
            _Section(
                title: t.homeFeatured,
                provider: featuredPropertiesProvider,
                repo: repo,
                hideWhenEmpty: true,
                horizontal: true),
            _Section(title: t.homeLatest, provider: latestPropertiesProvider, repo: repo),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        key: const Key('homeSearchBar'),
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(children: [
            Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(hint,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.provider,
    required this.repo,
    this.hideWhenEmpty = false,
    this.horizontal = false,
  });
  final bool horizontal;
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
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (horizontal && items.length > 1)
            LayoutBuilder(
              builder: (context, c) => SizedBox(
                height: 256,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) => PropertyCardTile(
                    property: items[i],
                    vertical: true,
                    width: (c.maxWidth * 0.62).clamp(190.0, 260.0).toDouble(),
                  ),
                ),
              ),
            )
          else
            for (final p in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PropertyCardTile(property: p),
              ),
        ]);
      },
    );
  }
}
