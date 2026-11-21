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

class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property, this.imageUrl, this.onTap});
  final PropertySummary property;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = property;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(fit: StackFit.expand, children: [
                imageUrl == null
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.home_work_outlined, size: 48))
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined)),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  start: AppSpacing.sm,
                  child: _Badge(transactionLabel(t, p.transactionType),
                      theme.colorScheme.secondary, Colors.black87),
                ),
                if (p.ownerVerified)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Icon(Icons.verified, color: theme.colorScheme.secondary),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      formatMoney(p.priceAmount, p.priceCurrency),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (p.priceNegotiable)
                    Text(t.negotiable, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(spacing: AppSpacing.md, children: [
                    if (p.bedrooms != null) _Stat(Icons.bed_outlined, '${p.bedrooms}'),
                    if (p.bathrooms != null) _Stat(Icons.bathtub_outlined, '${p.bathrooms}'),
                    if (p.areaSqm != null) _Stat(Icons.square_foot, '${p.areaSqm} ${t.sqm}'),
                  ]),
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(text,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(text),
      ]);
}
