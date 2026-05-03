import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/hive_box_names.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/theme/app_theme_controller.dart';
import 'data/datasources/hive_storage_service.dart';
import 'data/datasources/local_auth_service.dart';
import 'data/repositories/local_auth_repository.dart';
import 'domain/entities/expense.dart';
import 'domain/entities/user.dart';
import 'domain/usecases/auth/get_current_user_use_case.dart';
import 'domain/usecases/auth/login_use_case.dart';
import 'domain/usecases/auth/logout_use_case.dart';
import 'domain/usecases/auth/register_use_case.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/screens/app/expense_ui_demo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
    Hive.registerAdapter(UserAdapter());
  }
  if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  await Future.wait([
    Hive.openBox<User>(HiveBoxNames.users),
    Hive.openBox<Expense>(HiveBoxNames.expenses),
    Hive.openBox(HiveBoxNames.categories),
    Hive.openBox(HiveBoxNames.profile),
    Hive.openBox(HiveBoxNames.settings),
    Hive.openBox(HiveBoxNames.auth),
  ]);

  await LocalNotificationsService.instance.initialize();
  const storageService = HiveStorageService();
  const authService = LocalAuthService(storageService);
  const authRepository = LocalAuthRepository(authService);

  final userId = authService.getCurrentUser()?.id;
  final rawTheme = storageService.getUserThemeMode(userId: userId);
  AppThemeController.themeMode.value = AppThemeController.fromStorage(rawTheme);

  final pushEnabled = const HiveStorageService()
      .getUserPushNotificationsEnabled(userId: userId);
  await LocalNotificationsService.instance
      .syncDailyExpenseReminder(enabled: pushEnabled);

  final authBloc = AuthBloc(
    getCurrentUserUseCase: const GetCurrentUserUseCase(authRepository),
    loginUseCase: const LoginUseCase(authRepository),
    registerUseCase: const RegisterUseCase(authRepository),
    logoutUseCase: const LogoutUseCase(authRepository),
  )..add(const AuthSessionRequested());

  runApp(
    MyCashPlannerUiApp(
      authBloc: authBloc,
      authRepository: authRepository,
    ),
  );
}
