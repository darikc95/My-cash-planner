import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/hive_box_names.dart';
import 'core/notifications/local_notifications_service.dart';
import 'data/datasources/hive_storage_service.dart';
import 'data/datasources/local_auth_service.dart';
import 'domain/entities/expense.dart';
import 'domain/entities/user.dart';
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
  const authService = LocalAuthService(HiveStorageService());
  final userId = authService.getCurrentUser()?.id;
  final pushEnabled = const HiveStorageService()
      .getUserPushNotificationsEnabled(userId: userId);
  await LocalNotificationsService.instance
      .syncDailyExpenseReminder(enabled: pushEnabled);

  runApp(const MyCashPlannerUiApp());
}
