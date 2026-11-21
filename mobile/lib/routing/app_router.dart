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
  // null = signed in but the profile hasn't loaded yet (don't guess: avoids a Home flash).
  final needsOnboarding = ValueNotifier<bool?>(null);
  ref.listen<AsyncValue<Session?>>(sessionProvider, (_, next) {
    signedIn.value = next.value != null;
    needsOnboarding.value = next.value == null ? false : null;
  });
  ref.listen<AsyncValue<UserProfile?>>(profileProvider, (_, next) {
    if (next.isLoading) return; // keep the last known value while reloading
    if (next.hasError) {
      needsOnboarding.value = false; // don't trap the user if the profile can't load
      return;
    }
    final p = next.value;
    needsOnboarding.value = p == null ? null : !p.onboarded;
  });
  ref.onDispose(signedIn.dispose);
  ref.onDispose(needsOnboarding.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: Listenable.merge([signedIn, needsOnboarding]),
    redirect: (context, state) {
      // Without Supabase config (tests, local UI work) the app stays open.
      if (!Env.isSupabaseConfigured) return null;
      final loc = state.matchedLocation;
      final onAuth = loc == AppRoutes.login || loc == AppRoutes.verify;

      if (!signedIn.value) {
        return _requiresAccount(loc) ? _loginFor(state.uri.toString()) : null;
      }
      if (needsOnboarding.value == true && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      // Profile still loading right after login: stay put until we know where to go.
      if (needsOnboarding.value == null && onAuth) return null;
      if (needsOnboarding.value == false && loc == AppRoutes.onboarding) {
        return AppRoutes.home;
      }
      if (onAuth) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.startsWith('/')) ? from : AppRoutes.home;
      }
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
