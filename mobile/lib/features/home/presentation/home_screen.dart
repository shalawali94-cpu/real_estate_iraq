import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/phase_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
        title: AppLocalizations.of(context).appTitle,
        icon: Icons.home_work_outlined,
      );
}
