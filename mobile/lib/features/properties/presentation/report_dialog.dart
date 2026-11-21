import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';

const _reasons = ['fake', 'wrong_price', 'sold', 'duplicate', 'fraud', 'offensive', 'other'];

String _label(AppLocalizations t, String r) => switch (r) {
      'fake' => t.reportFake,
      'wrong_price' => t.reportWrongPrice,
      'sold' => t.reportSold,
      'duplicate' => t.reportDuplicate,
      'fraud' => t.reportFraud,
      'offensive' => t.reportOffensive,
      _ => t.reportOther,
    };

/// Lets a signed-in user report a listing. Inserted under RLS; one report per
/// user per listing (a repeat is treated as already reported).
Future<void> showReportDialog(BuildContext context, String propertyId) async {
  final t = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    final from = GoRouterState.of(context).uri.toString();
    context.push('/login?from=${Uri.encodeComponent(from)}');
    return;
  }
  String reason = 'fake';
  final details = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(t.reportTitle),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            RadioGroup<String>(
              groupValue: reason,
              onChanged: (v) => setState(() => reason = v ?? reason),
              child: Column(children: [
                for (final r in _reasons)
                  RadioListTile<String>(
                    dense: true,
                    value: r,
                    title: Text(_label(t, r)),
                  ),
              ]),
            ),
            TextField(
              controller: details,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(hintText: t.reportDetailsHint),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.reportSend)),
        ],
      ),
    ),
  );
  final text = details.text.trim();
  details.dispose();
  if (ok != true) return;
  try {
    await client.from('property_reports').insert({
      'property_id': propertyId,
      'reporter_id': uid,
      'reason': reason,
      if (text.isNotEmpty) 'details': text,
    });
    messenger.showSnackBar(SnackBar(content: Text(t.reportThanks)));
  } on PostgrestException catch (e) {
    // 23505 = already reported by this user.
    messenger.showSnackBar(SnackBar(
        content: Text(e.code == '23505' ? t.reportThanks : t.authGenericError)));
  }
}
