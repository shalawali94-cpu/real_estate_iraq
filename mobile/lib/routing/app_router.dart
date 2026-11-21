import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/verify_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_form_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/property_creation/presentation/add_property_screen.dart';
import '../features/property_creation/presentation/media_screen.dart';
import '../shared/widgets/main_shell.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const explore = '/explore';
  static const add = '/add';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const login = '/login';
  static const verify = '/verify';
  static const onboarding = '/onboarding';
}

/// Browsing (home, explore, details) is open to guests. These need an account.
bool _requiresAccount(String loc) =>
    loc.startsWith(AppRoutes.add) ||
    loc.startsWith(AppRoutes.favorites) ||
    loc.startsWith('/draft') ||
    loc.startsWith('/profile/edit');

String _loginFor(String from) =>
    '${AppRoutes.login}?from=${Uri.encodeComponent(from)}';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects when auth/profile state changes, without rebuilding the router.
  final signedIn = ValueNotifier<bool>(
    ref.read(authRepositoryProvider)?.currentSession != null,
  );
  // Redirects read the live provider state; this notifier only asks the router to
  // re-run them whenever auth or profile state changes (no mirrored copy to go stale).
  final tick = ValueNotifier<int>(0);
  void poke() => tick.value++;
  ref.listen<AsyncValue<Session?>>(sessionProvider, (_, next) {
    signedIn.value = next.value != null;
    poke();
  });
  ref.listen<AsyncValue<UserProfile?>>(profileProvider, (_, _) => poke());
  ref.onDispose(signedIn.dispose);
  ref.onDispose(tick.dispose);

  /// null = signed in but the profile is not known yet (avoids a Home flash).
  bool? needsOnboarding() {
    final prof = ref.read(profileProvider);
    if (prof.hasError) return false; // don't trap the user if it can't load
    final p = prof.value;
    if (p == null) return null;
    return !p.onboarded;
  }

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: Listenable.merge([signedIn, tick]),
    redirect: (context, state) {
      // Without Supabase config (tests, local UI work) the app stays open.
      if (!Env.isSupabaseConfigured) return null;
      final loc = state.matchedLocation;

      if (!signedIn.value) {
        return _requiresAccount(loc) ? _loginFor(state.uri.toString()) : null;
      }
      final needs = needsOnboarding();
      if (needs == true && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      // Leaving login/verify (and onboarding) is done by those screens with go(),
      // which replaces the whole stack. A redirect here could recreate a page that is
      // already in the stack (e.g. /profile under the pushed login) and crash.
      return null;
    },
    routes: [
      GoRoute(
        path: '/property/:id',
        builder: (_, state) => PropertyDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/draft/:id/media',
        builder: (_, state) => MediaScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.verify,
        builder: (_, state) => VerifyScreen(phone: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const ProfileFormScreen(editMode: false),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const ProfileFormScreen(editMode: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.explore, builder: (_, _) => const ExploreScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.add, builder: (_, _) => const AddPropertyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.favorites, builder: (_, _) => const FavoritesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
