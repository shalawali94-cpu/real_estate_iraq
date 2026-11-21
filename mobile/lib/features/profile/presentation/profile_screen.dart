import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../localization/app_settings_controllers.dart';
import '../../../theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../admin/presentation/admin_review_screen.dart';
import '../../authentication/data/auth_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../data/profile_repository.dart';

/// Guest view (no account) or the signed-in user's profile, plus app settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _accountLabel(AppLocalizations t, String type) => switch (type) {
        'owner' => t.accountOwner,
        'agent' => t.accountAgent,
        'company' => t.accountCompany,
        'developer' => t.accountDeveloper,
        _ => t.accountIndividual,
      };

  String _roleLabel(AppLocalizations t, String? role) => switch (role) {
        'super_admin' => t.roleSuperAdmin,
        'admin' => t.roleAdmin,
        'moderator' => t.roleModerator,
        _ => t.roleMember,
      };

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.deleteAccountTitle),
        content: Text(t.deleteAccountBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          TextButton(
            key: const Key('confirmDeleteButton'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiClientProvider)!.post('/api/v1/account/delete', const {});
      await ref.read(authRepositoryProvider)!.signOut();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.deleteAccountFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final signedIn = ref.watch(sessionProvider).value != null;
    final profile = ref.watch(profileProvider).value;
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
          if (!signedIn)
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(children: [
                  Icon(Icons.account_circle_outlined, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(t.profileGuestTitle,
                      textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.profileGuestBody, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    key: const Key('profileSignInButton'),
                    onPressed: () => context.push('/login?from=%2Fprofile'),
                    child: Text(t.authSignIn),
                  ),
                ]),
              ),
            )
          else
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        (profile?.fullName?.trim().isNotEmpty ?? false)
                            ? profile!.fullName!.trim().characters.first
                            : '?',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(profile?.fullName ?? '—', style: theme.textTheme.titleMedium),
                        if (profile?.phone != null)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('+${profile!.phone!.replaceAll('+', '')}'),
                          ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(spacing: AppSpacing.sm, children: [
                    Chip(label: Text(_accountLabel(t, profile?.accountType ?? 'individual'))),
                    Chip(
                      avatar: profile?.isStaff == true
                          ? const Icon(Icons.shield_outlined, size: 16)
                          : null,
                      label: Text(_roleLabel(t, profile?.topRole)),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('editProfileButton'),
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t.editProfile),
                  ),
                  if (ref.watch(isStaffProvider).value ?? false)
                    FilledButton.icon(
                      key: const Key('adminButton'),
                      onPressed: () => context.push('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: Text(t.adminOpenButton),
                    ),
                  OutlinedButton.icon(
                    key: const Key('myPropertiesButton'),
                    onPressed: () => context.push('/profile/properties'),
                    icon: const Icon(Icons.home_work_outlined),
                    label: Text(t.myPropertiesTitle),
                  ),
                  OutlinedButton.icon(
                    key: const Key('notificationsButton'),
                    onPressed: () => context.push('/notifications'),
                    icon: Badge(
                      isLabelVisible: (ref.watch(unreadNotificationsProvider).value ?? 0) > 0,
                      label: Text('${ref.watch(unreadNotificationsProvider).value ?? 0}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    label: Text(t.notificationsButton),
                  ),
                  OutlinedButton.icon(
                    key: const Key('messagesButton'),
                    onPressed: () => context.push('/messages'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(t.messagesTitle),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.settingsLanguage, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            key: const Key('languageSelector'),
            segments: [
              for (final e in languages.entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) =>
                ref.read(localeControllerProvider.notifier).setLocale(Locale(s.first)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.settingsTheme, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeControllerProvider.notifier).setThemeMode(s.first),
          ),
          if (signedIn) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              key: const Key('signOutButton'),
              onPressed: () => ref.read(authRepositoryProvider)!.signOut(),
              icon: const Icon(Icons.logout),
              label: Text(t.authSignOut),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('deleteAccountButton'),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _deleteAccount(context, ref),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(t.deleteAccount),
            ),
          ],
        ],
      ),
    );
  }
}
