import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../application/planner_facade.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

const _avatarOptions = <_AvatarOption>[
  _AvatarOption(Icons.person_rounded, Color(0xFF6C45E3), Color(0xFFEFEAFF)),
  _AvatarOption(Icons.face_rounded, Color(0xFF4A86F7), Color(0xFFE8F0FF)),
  _AvatarOption(Icons.sentiment_very_satisfied_rounded, Color(0xFF1DB954),
      Color(0xFFE8FAF0)),
  _AvatarOption(
      Icons.auto_awesome_rounded, Color(0xFFFFBF33), Color(0xFFFFF9E6)),
  _AvatarOption(
      Icons.sports_esports_rounded, Color(0xFF8D5CF6), Color(0xFFF3EDFF)),
  _AvatarOption(
      Icons.rocket_launch_rounded, Color(0xFFFF5E94), Color(0xFFFFEDF4)),
  _AvatarOption(
      Icons.self_improvement_rounded, Color(0xFF00B8D4), Color(0xFFE5F9FC)),
  _AvatarOption(Icons.local_fire_department_rounded, Color(0xFFFF7A59),
      Color(0xFFFFF0EC)),
];

class _AvatarOption {
  const _AvatarOption(this.icon, this.color, this.background);
  final IconData icon;
  final Color color;
  final Color background;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _planner = PlannerFacade.instance;

  int _avatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatarIndex();
  }

  void _loadAvatarIndex() {
    final userId = _planner.getCurrentUser()?.id;
    if (userId != null) {
      setState(() {
        _avatarIndex = _planner.getUserAvatarIndex(userId);
      });
    }
  }

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

  Future<void> _handleSelectAvatar() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _AvatarPickerDialog(currentIndex: _avatarIndex),
    );

    if (!mounted || selected == null) return;

    final userId = _planner.getCurrentUser()?.id;
    if (userId != null) {
      await _planner.saveUserAvatarIndex(userId, selected);
    }

    setState(() => _avatarIndex = selected);
  }

  Future<void> _handleEditProfile(AuthState state) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      _showMessage('Пользователь не найден.');
      return;
    }
    var draftName = currentUser.name;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Личные данные'),
          content: TextFormField(
            initialValue: draftName,
            decoration: const InputDecoration(labelText: 'Имя'),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) => draftName = value,
            onFieldSubmitted: (v) {
              Navigator.of(dialogContext).pop(v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(draftName),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty) return;
    if (!mounted) return;

    final result = await _planner.updateProfile(
      userId: currentUser.id,
      name: newName.trim(),
    );

    if (!mounted) return;

    _showMessage(
      result.success
          ? 'Профиль обновлён.'
          : (result.message ?? 'Не удалось обновить профиль.'),
    );

    if (result.success && mounted) {
      context.read<AuthBloc>().add(const AuthSessionRequested());
    }
  }

  Future<void> _handleChangePassword(AuthState state) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      _showMessage('Пользователь не найден.');
      return;
    }

    var currentPassword = '';
    var newPassword = '';

    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Безопасность'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Текущий пароль'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: (value) => currentPassword = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onChanged: (value) => newPassword = value,
                onFieldSubmitted: (_) {
                  Navigator.of(dialogContext).pop({
                    'currentPassword': currentPassword,
                    'newPassword': newPassword,
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (credentials == null || !mounted) return;

    final result = await _planner.changePassword(
      userId: currentUser.id,
      currentPassword: credentials['currentPassword'] ?? '',
      newPassword: credentials['newPassword'] ?? '',
    );

    if (!mounted) return;

    _showMessage(
      result.success
          ? 'Пароль обновлён.'
          : (result.message ?? 'Не удалось обновить пароль.'),
    );
  }

  Future<void> _handleBudgetLimit() async {
    final userId = _planner.getCurrentUser()?.id;
    if (userId == null) {
      _showMessage('Пользователь не найден.');
      return;
    }

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final currentLimit =
        _planner.getUserBudgetLimit(userId, month: currentMonth);
    String inputValue =
        currentLimit != null ? currentLimit.toStringAsFixed(0) : '';

    final result = await showDialog<double?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Лимит бюджета (${_formatMonthYear(currentMonth)})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Установите максимальную сумму расходов для текущего месяца. '
              'Значение будет автоматически использоваться и в следующих '
              'месяцах, пока вы его не измените.',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: inputValue,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Лимит (₸)',
                suffixText: '₸',
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (v) => inputValue = v,
              onFieldSubmitted: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                Navigator.of(dialogContext).pop(parsed);
              },
            ),
          ],
        ),
        actions: [
          if (currentLimit != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(-1.0),
              child: const Text('Удалить лимит'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final parsed =
                  double.tryParse(inputValue.trim().replaceAll(',', '.'));
              Navigator.of(dialogContext).pop(parsed);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    if (result < 0) {
      await _planner.clearUserBudgetLimit(userId, month: currentMonth);
      if (!mounted) return;
      setState(() {});
      _showMessage(
          'Лимит бюджета за ${_formatMonthYear(currentMonth)} удалён.');
      return;
    }

    if (result <= 0) {
      _showMessage('Введите сумму больше нуля.');
      return;
    }

    await _planner.saveUserBudgetLimit(
      userId,
      result,
      month: currentMonth,
    );
    if (!mounted) return;
    setState(() {});
    _showMessage(
      'Лимит за ${_formatMonthYear(currentMonth)} сохранён: '
      '${result.toStringAsFixed(0)} ₸.',
    );
  }

  Future<void> _handleNotifications() async {
    final userId = _planner.getCurrentUser()?.id;
    var pushNotifications =
        _planner.getUserPushNotificationsEnabled(userId: userId);
    var budgetAlerts = _planner.getUserBudgetAlertsEnabled(userId: userId);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: pushNotifications,
                    title: const Text('Push-уведомления'),
                    subtitle: const Text('Напоминания о новых расходах'),
                    onChanged: (value) async {
                      if (!value) {
                        setSheetState(() => pushNotifications = false);
                        await _planner.saveUserPushNotificationsEnabled(
                          false,
                          userId: userId,
                        );
                        await LocalNotificationsService.instance
                            .syncDailyExpenseReminder(enabled: false);
                        return;
                      }

                      final granted = await LocalNotificationsService.instance
                          .ensurePermissionsGranted();
                      if (!granted) {
                        setSheetState(() => pushNotifications = false);
                        await _planner.saveUserPushNotificationsEnabled(
                          false,
                          userId: userId,
                        );
                        if (!mounted) return;
                        _showMessage(
                          'Разрешите уведомления в настройках приложения.',
                        );
                        return;
                      }

                      setSheetState(() => pushNotifications = true);
                      await _planner.saveUserPushNotificationsEnabled(
                        true,
                        userId: userId,
                      );
                      await LocalNotificationsService.instance
                          .syncDailyExpenseReminder(enabled: true);
                      await LocalNotificationsService.instance
                          .showPushEnabledTest();
                    },
                  ),
                  SwitchListTile(
                    value: budgetAlerts,
                    title: const Text('Контроль бюджета'),
                    subtitle: const Text('Предупреждать о превышении лимита'),
                    onChanged: (value) {
                      setSheetState(() => budgetAlerts = value);
                      _planner.saveUserBudgetAlertsEnabled(
                        value,
                        userId: userId,
                      );
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

  Future<void> _handleThemeMode() async {
    final userId = _planner.getCurrentUser()?.id;
    var isDark = AppThemeController.themeMode.value == ThemeMode.dark;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: isDark,
                    title: const Text('Тёмная тема'),
                    subtitle: const Text('Переключить между светлой и тёмной'),
                    onChanged: (value) async {
                      setSheetState(() => isDark = value);
                      final mode = value ? ThemeMode.dark : ThemeMode.light;
                      AppThemeController.themeMode.value = mode;
                      await _planner.saveUserThemeMode(
                        AppThemeController.toStorage(mode),
                        userId: userId,
                      );
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

  Future<void> _handleSupport() async {
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
            Text('369032@gmail.com'),
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

    if (!mounted) return;
    _showMessage('Email поддержки скопирован.');
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
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

          final userId = currentUser?.id;
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final budgetLimit = userId != null
              ? _planner.getUserBudgetLimit(userId, month: currentMonth)
              : null;

          final avatarOpt =
              _avatarOptions[_avatarIndex.clamp(0, _avatarOptions.length - 1)];

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
                              GestureDetector(
                                onTap: _handleSelectAvatar,
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 64,
                                      width: 64,
                                      decoration: BoxDecoration(
                                        color: avatarOpt.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        avatarOpt.icon,
                                        size: 32,
                                        color: avatarOpt.color,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        height: 22,
                                        width: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C45E3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
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
                        onTap: () => _handleEditProfile(state),
                      ),
                      _ProfileActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Безопасность',
                        onTap: () => _handleChangePassword(state),
                      ),
                      _ProfileActionTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Лимит бюджета',
                        subtitle: budgetLimit != null
                            ? '${_formatMonthYear(currentMonth)}: '
                                '${budgetLimit.toStringAsFixed(0)} ₸'
                            : 'Не задан',
                        onTap: _handleBudgetLimit,
                      ),
                      _ProfileActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомления',
                        onTap: _handleNotifications,
                      ),
                      _ProfileActionTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Тема оформления',
                        subtitle:
                            AppThemeController.themeMode.value == ThemeMode.dark
                                ? 'Тёмная'
                                : 'Светлая',
                        onTap: _handleThemeMode,
                      ),
                      _ProfileActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Поддержка',
                        onTap: _handleSupport,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _handleLogout,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFF6C45E3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          state.isSubmitting ? 'Выходим...' : 'Выйти',
                        ),
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

class _AvatarPickerDialog extends StatefulWidget {
  const _AvatarPickerDialog({required this.currentIndex});

  final int currentIndex;

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выбор аватара'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(_avatarOptions.length, (index) {
          final opt = _avatarOptions[index];
          final isSelected = index == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: opt.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF6C45E3) : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        const BoxShadow(
                          color: Color(0x336C45E3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(opt.icon, color: opt.color, size: 28),
            ),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
