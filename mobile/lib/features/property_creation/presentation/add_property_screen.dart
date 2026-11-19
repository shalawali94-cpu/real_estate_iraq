import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/phase_placeholder.dart';

class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) => PhasePlaceholder(
        title: AppLocalizations.of(context).addPropertyTitle,
        icon: Icons.add_home_outlined,
      );
}
