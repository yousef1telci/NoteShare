import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/main/presentation/main_shell.dart';
import '../../features/classes/presentation/my_classes_screen.dart';
import '../../features/classes/presentation/discover_classes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/classes/presentation/class_detail_screen.dart';
import '../../features/classes/domain/class_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/my-classes',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final session = authState.value?.session;
      final isAuth = session != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      if (isAuth && isLoggingIn) {
        return '/my-classes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/my-classes',
            builder: (context, state) => const MyClassesScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverClassesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/class-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final cls = state.extra as ClassModel?;
          final classId = state.uri.queryParameters['id'] ?? cls?.id ?? '';
          final className = state.uri.queryParameters['name'] ?? cls?.name ?? 'Class Details';
          return ClassDetailScreen(
            classId: classId, 
            className: className,
            classModel: cls,
          );
        },
      ),
    ],
  );
});
