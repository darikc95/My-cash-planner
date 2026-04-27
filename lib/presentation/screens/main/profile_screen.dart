import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/hive_box_names.dart';
import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _pushNotificationsKey = 'settings.notifications.push';
  static const _budgetAlertsKey = 'settings.notifications.budget';

  LocalAuthService get _authService =>
      const LocalAuthService(HiveStorageService());

  Box<dynamic> get _settingsBox => Hive.box<dynamic>(HiveBoxNames.settings);

  void _handleBottomBarTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(ExpenseUiRoutes.home);
      case 1:
        context.go(ExpenseUiRoutes.statistics);
      case 2:
        context.go(ExpenseUiRoutes.categories);
      case 3:
        context.go(ExpenseUiRoutes.profile);
    }
  }

  Future<void> _handleEditProfile(
    BuildContext context,
    AuthState state,
  ) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      _showMessage(context, 'Пользователь не найден.');
      return;
    }

    final controller = TextEditingController(text: currentUser.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Личные данные'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Имя'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.trim().isEmpty || !context.mounted) {
      return;
    }

    final result = await _authService.updateProfile(
      userId: currentUser.id,
      name: newName,
    );

    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      result.success
          ? 'Профиль обновлён.'
          : (result.message ?? 'Не удалось обновить профиль.'),
    );

    if (result.success) {
      context.read<AuthBloc>().add(const AuthSessionRequested());
    }
  }

  Future<void> _handleChangePassword(
    BuildContext context,
    AuthState state,
  ) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      _showMessage(context, 'Пользователь не найден.');
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Безопасность'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Текущий пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'Новый пароль'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop({
              'currentPassword': currentPasswordController.text,
              'newPassword': newPasswordController.text,
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();

    if (credentials == null || !context.mounted) {
      return;
    }

    final result = await _authService.changePassword(
      userId: currentUser.id,
      currentPassword: credentials['currentPassword'] ?? '',
      newPassword: credentials['newPassword'] ?? '',
    );

    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      result.success
          ? 'Пароль обновлён.'
          : (result.message ?? 'Не удалось обновить пароль.'),
    );
  }

  Future<void> _handleNotifications(BuildContext context) async {
    var pushNotifications =
        (_settingsBox.get(_pushNotificationsKey) as bool?) ?? true;
    var budgetAlerts = (_settingsBox.get(_budgetAlertsKey) as bool?) ?? true;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: pushNotifications,
                    title: const Text('Push-уведомления'),
                    subtitle: const Text('Напоминания о новых расходах'),
                    onChanged: (value) {
                      setSheetState(() {
                        pushNotifications = value;
                      });
                      _settingsBox.put(_pushNotificationsKey, value);
                    },
                  ),
                  SwitchListTile(
                    value: budgetAlerts,
                    title: const Text('Контроль бюджета'),
                    subtitle: const Text('Предупреждать о превышении лимита'),
                    onChanged: (value) {
                      setSheetState(() {
                        budgetAlerts = value;
                      });
                      _settingsBox.put(_budgetAlertsKey, value);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSupport(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Поддержка'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Если возникли вопросы, напишите нам:'),
            SizedBox(height: 8),
            Text('support@mycashplanner.app'),
            SizedBox(height: 12),
            Text('Обычно отвечаем в течение одного рабочего дня.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );

    await Clipboard.setData(
      const ClipboardData(text: 'support@mycashplanner.app'),
    );

    if (!context.mounted) {
      return;
    }

    _showMessage(context, 'Email поддержки скопирован.');
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.flowAction != current.flowAction,
      listener: (context, state) {
        if (state.flowAction == AuthFlowAction.loggedOut) {
          context.go(ExpenseUiRoutes.login);
          context.read<AuthBloc>().add(const AuthMessageHandled());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final currentUser = state.currentUser;
          final userName = (currentUser?.name ?? '').trim().isNotEmpty
              ? currentUser!.name
              : 'Пользователь';
          final userEmail = (currentUser?.email ?? '').trim().isNotEmpty
              ? currentUser!.email
              : 'Нет данных';

          return Scaffold(
            floatingActionButton: PrimaryFab(
              onPressed: () => context.push(ExpenseUiRoutes.addExpense),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: AppBottomBar(
              currentIndex: 3,
              onTap: (index) => _handleBottomBarTap(context, index),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                    children: [
                      Text(
                        'Профиль',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFEAFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: Color(0xFF6C45E3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: const Color(0xFF252A39),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userEmail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProfileActionTile(
                        icon: Icons.badge_outlined,
                        title: 'Личные данные',
                        onTap: () => _handleEditProfile(context, state),
                      ),
                      _ProfileActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Безопасность',
                        onTap: () => _handleChangePassword(context, state),
                      ),
                      _ProfileActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомления',
                        onTap: () => _handleNotifications(context),
                      ),
                      _ProfileActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Поддержка',
                        onTap: () => _handleSupport(context),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _handleLogout(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFF6C45E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child:
                            Text(state.isSubmitting ? 'Выходим...' : 'Выйти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: const Color(0xFF6C45E3)),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF252A39),
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
