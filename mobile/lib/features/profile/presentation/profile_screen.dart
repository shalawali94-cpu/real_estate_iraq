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

    final isStaff = ref.watch(isStaffProvider).value ?? false;
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;

    Widget section(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6, top: AppSpacing.md),
              child: Text(title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              clipBehavior: Clip.antiAlias,
              child: Column(children: children),
            ),
          ],
        );

    Widget item(Key key, IconData icon, String label, VoidCallback onTap, {Widget? trailing}) =>
        ListTile(
          key: key,
          leading: Icon(icon),
          title: Text(label),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: Text(t.navProfile)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
            children: [
              if (!signedIn)
                Card(
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(children: [
                      Icon(Icons.account_circle_outlined,
                          size: 56, color: theme.colorScheme.primary),
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
              else ...[
                Card(
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
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
                          Text(profile?.fullName ?? '—',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          if (profile?.phone != null)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text('+${profile!.phone!.replaceAll('+', '')}',
                                  style: theme.textTheme.bodySmall),
                            ),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 4, children: [
                            _Pill(_accountLabel(t, profile?.accountType ?? 'individual')),
                            if (profile?.topRole != null || profile?.isStaff == true)
                              _Pill(_roleLabel(t, profile?.topRole),
                                  icon: profile?.isStaff == true ? Icons.shield_outlined : null),
                          ]),
                        ]),
                      ),
                      IconButton(
                        key: const Key('editProfileButton'),
                        tooltip: t.editProfile,
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ]),
                  ),
                ),
                if (isStaff) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('adminButton'),
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(t.adminOpenButton),
                  ),
                ],
                section(t.profileMyActivity, [
                  item(const Key('myPropertiesButton'), Icons.home_work_outlined,
                      t.myPropertiesTitle, () => context.push('/profile/properties')),
                  const Divider(height: 1),
                  item(const Key('messagesButton'), Icons.chat_bubble_outline, t.messagesTitle,
                      () => context.push('/messages')),
                  const Divider(height: 1),
                  item(const Key('notificationsButton'), Icons.notifications_outlined,
                      t.notificationsButton, () => context.push('/notifications'),
                      trailing: unread > 0
                          ? Badge(label: Text('$unread'), child: const Icon(Icons.chevron_right))
                          : null),
                ]),
              ],
              section(t.settingsLanguage, [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: SegmentedButton<String>(
                    key: const Key('languageSelector'),
                    showSelectedIcon: false,
                    segments: [
                      for (final e in languages.entries)
                        ButtonSegment(value: e.key, label: Text(e.value)),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (s) => ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(Locale(s.first)),
                  ),
                ),
              ]),
              section(t.settingsTheme, [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
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
                ),
              ]),
              if (signedIn) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  key: const Key('signOutButton'),
                  onPressed: () => ref.read(authRepositoryProvider)!.signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(t.authSignOut),
                ),
                const SizedBox(height: AppSpacing.xs),
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
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
          Text(text, style: theme.textTheme.labelSmall),
        ]),
      ),
    );
  }
}
