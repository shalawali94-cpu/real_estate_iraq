import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/phase_placeholder.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
        title: AppLocalizations.of(context).navFavorites,
        icon: Icons.favorite_border,
      );
}
