// Слой: core | Назначение: конфигурация GoRouter с редиректом по состоянию сессии

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/screens/analytics_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/splash_screen.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: _AuthStateListenable(authBloc),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister;
      final isSplash = state.matchedLocation == AppConstants.routeSplash;

      if (authState is AuthLoading || authState is AuthInitial) {
        return isSplash ? null : AppConstants.routeSplash;
      }

      if (authState is AuthAuthenticated) {
        return isAuthRoute || isSplash ? AppConstants.routeHome : null;
      }

      if (authState is AuthUnauthenticated) {
        return isAuthRoute ? null : AppConstants.routeLogin;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAnalytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
  );
}

// Уведомляет GoRouter об изменениях состояния AuthBloc
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
}
