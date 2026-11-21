import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/property_summary.dart';

String transactionLabel(AppLocalizations t, String type) => switch (type) {
      'sale' => t.txSale,
      'rent' => t.txRent,
      'short_term_rent' => t.txShortTermRent,
      'investment' => t.txInvestment,
      _ => type,
    };

/// Compact card for phones. Default is a horizontal row (photo on the side);
/// `vertical` is a small tile for horizontal carousels.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.imageUrl,
    this.onTap,
    this.isFavorite,
    this.onFavorite,
    this.vertical = false,
  });
  final PropertySummary property;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool? isFavorite; // null hides the heart (signed out / unconfigured)
  final VoidCallback? onFavorite;
  final bool vertical;

  Widget _photo(BuildContext context, AppLocalizations t, ThemeData theme) {
    final p = property;
    return Stack(fit: StackFit.expand, children: [
      imageUrl == null
          ? ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.home_work_outlined, size: 36))
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined)),
      PositionedDirectional(
        top: 6,
        start: 6,
        child: _Badge(transactionLabel(t, p.transactionType), theme.colorScheme.secondary,
            Colors.black87),
      ),
      if (p.ownerVerified)
        PositionedDirectional(
          bottom: 6,
          start: 6,
          child: Icon(Icons.verified, size: 18, color: theme.colorScheme.secondary),
        ),
    ]);
  }

  Widget _heart() => IconButton(
        key: const Key('favoriteButton'),
        visualDensity: VisualDensity.compact,
        onPressed: onFavorite,
        icon: Icon(
          isFavorite! ? Icons.favorite : Icons.favorite_border,
          size: 22,
          color: isFavorite! ? Colors.redAccent : null,
        ),
      );

  Widget _info(BuildContext context, AppLocalizations t, ThemeData theme) {
    final p = property;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            formatMoney(p.priceAmount, p.priceCurrency),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        Text(p.title,
            maxLines: vertical ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Wrap(spacing: AppSpacing.sm, runSpacing: 2, children: [
          if (p.bedrooms != null) _Stat(Icons.bed_outlined, '${p.bedrooms}'),
          if (p.bathrooms != null) _Stat(Icons.bathtub_outlined, '${p.bathrooms}'),
          if (p.areaSqm != null) _Stat(Icons.square_foot, '${p.areaSqm} ${t.sqm}'),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (vertical) {
      return SizedBox(
        width: 210,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(aspectRatio: 4 / 3, child: _photo(context, t, theme)),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _info(context, t, theme),
              ),
            ]),
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 118,
          child: Row(children: [
            SizedBox(width: 118, child: _photo(context, t, theme)),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _info(context, t, theme)),
                  if (isFavorite != null) _heart(),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.bg, this.fg);
  final String text;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(text,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]);
}
