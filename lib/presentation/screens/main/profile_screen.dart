import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  void _handleProfileAction(BuildContext context, String actionName) {
    showFeatureStub(context, actionName);
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
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
                        onTap: () => _handleProfileAction(
                          context,
                          'Редактирование профиля',
                        ),
                      ),
                      _ProfileActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Безопасность',
                        onTap: () => _handleProfileAction(
                          context,
                          'Настройки безопасности',
                        ),
                      ),
                      _ProfileActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомления',
                        onTap: () => _handleProfileAction(
                          context,
                          'Настройки уведомлений профиля',
                        ),
                      ),
                      _ProfileActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Поддержка',
                        onTap: () => _handleProfileAction(context, 'Поддержка'),
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
