import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/hive_box_names.dart';
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

  runApp(const MyCashPlannerUiApp());
}
