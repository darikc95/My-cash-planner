import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();
    context.push(ExpenseUiRoutes.register);
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    var resetEmail = _emailController.text;
    var resetPassword = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Сброс пароля'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: resetEmail,
                  decoration: const InputDecoration(labelText: 'Эл. почта'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => resetEmail = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: resetPassword,
                  decoration: const InputDecoration(labelText: 'Новый пароль'),
                  obscureText: true,
                  onChanged: (v) => resetPassword = v,
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
              onPressed: () {
                Navigator.of(dialogContext).pop({
                  'email': resetEmail,
                  'password': resetPassword,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    const authService = LocalAuthService(HiveStorageService());
    final resetResult = await authService.resetPassword(
      email: result['email'] ?? '',
      newPassword: result['password'] ?? '',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resetResult.success
                ? 'Пароль обновлён. Теперь можно войти.'
                : (resetResult.message ?? 'Не удалось сбросить пароль.'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.flowAction != current.flowAction,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          context.read<AuthBloc>().add(const AuthMessageHandled());
        }

        if (state.flowAction == AuthFlowAction.loggedIn) {
          context.read<AuthBloc>().add(const AuthMessageHandled());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(ExpenseUiRoutes.home);
          });
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        const WalletIllustration(),
                        const SizedBox(height: 28),
                        Text(
                          'С возвращением!',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 32,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Войдите, чтобы продолжить',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 26),
                        AuthTextField(
                          icon: Icons.mail_outline_rounded,
                          label: 'Эл. почта',
                          controller: _emailController,
                          hintText: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          icon: Icons.lock_outline_rounded,
                          label: 'Пароль',
                          controller: _passwordController,
                          hintText: 'Введите пароль',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Забыли пароль?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: const Color(0xFF6C45E3),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: state.isSubmitting ? null : _handleLogin,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: const Color(0xFF6C45E3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child:
                              Text(state.isSubmitting ? 'Входим...' : 'Войти'),
                        ),
                        const SizedBox(height: 26),
                        TextButton(
                          onPressed: _handleRegister,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: const [
                                TextSpan(text: 'Нет аккаунта? '),
                                TextSpan(
                                  text: 'Регистрация',
                                  style: TextStyle(
                                    color: Color(0xFF6C45E3),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
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
