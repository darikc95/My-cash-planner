import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../domain/usecases/auth/get_current_user_use_case.dart';
import '../../../domain/usecases/auth/login_use_case.dart';
import '../../../domain/usecases/auth/logout_use_case.dart';
import '../../../domain/usecases/auth/register_use_case.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'expense_ui_routes.dart';

class MyCashPlannerUiApp extends StatefulWidget {
  const MyCashPlannerUiApp({super.key});

  @override
  State<MyCashPlannerUiApp> createState() => _MyCashPlannerUiAppState();
}

class _MyCashPlannerUiAppState extends State<MyCashPlannerUiApp> {
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    final userId = _authService.getCurrentUser()?.id;
    final rawTheme = _storageService.getUserThemeMode(userId: userId);
    AppThemeController.themeMode.value =
        AppThemeController.fromStorage(rawTheme);

    const authService = LocalAuthService(HiveStorageService());
    _authBloc = AuthBloc(
      getCurrentUserUseCase: const GetCurrentUserUseCase(authService),
      loginUseCase: const LoginUseCase(authService),
      registerUseCase: const RegisterUseCase(authService),
      logoutUseCase: const LogoutUseCase(authService),
    )..add(const AuthSessionRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.themeMode,
        builder: (_, themeMode, __) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Мой бюджет',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeMode,
            routerConfig: expenseUiRouter,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const accent = Color(0xFF6C45E3);
    const surface = Color(0xFFF7F6FB);
    const text = Color(0xFF202330);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F2FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: const Color(0xFFBDAEFF),
        surface: surface,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const accent = Color(0xFF8E73EA);
    const text = Color(0xFFEAEAF2);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF14151B),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        secondary: const Color(0xFFAFA2E8),
        surface: const Color(0xFF1D1F28),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Color(0xFFB2B7C6),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1D1F28),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252834),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
