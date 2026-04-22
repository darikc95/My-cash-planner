import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../domain/usecases/auth/get_current_user_use_case.dart';
import '../../../domain/usecases/auth/login_use_case.dart';
import '../../../domain/usecases/auth/logout_use_case.dart';
import '../../../domain/usecases/auth/register_use_case.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'expense_ui_routes.dart';

class MyCashPlannerUiApp extends StatelessWidget {
  const MyCashPlannerUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const authService = LocalAuthService(HiveStorageService());

    return BlocProvider(
      create: (_) => AuthBloc(
        getCurrentUserUseCase: const GetCurrentUserUseCase(authService),
        loginUseCase: const LoginUseCase(authService),
        registerUseCase: const RegisterUseCase(authService),
        logoutUseCase: const LogoutUseCase(authService),
      )..add(const AuthSessionRequested()),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Мой бюджет',
        theme: _buildTheme(),
        routerConfig: expenseUiRouter,
      ),
    );
  }

  ThemeData _buildTheme() {
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
}
