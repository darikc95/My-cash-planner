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

    final emailController = TextEditingController(text: _emailController.text);
    final passwordController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Сброс пароля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Эл. почта'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
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
              onPressed: () {
                Navigator.of(dialogContext).pop({
                  'email': emailController.text,
                  'password': passwordController.text,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();

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

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();

    const authService = LocalAuthService(HiveStorageService());
    final result = await authService.loginWithDemoAccount();

    if (!mounted) {
      return;
    }

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Не удалось выполнить demo-вход.'),
          ),
        );
      return;
    }

    context.read<AuthBloc>().add(const AuthSessionRequested());
    context.go(ExpenseUiRoutes.home);
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
          context.go(ExpenseUiRoutes.home);
          context.read<AuthBloc>().add(const AuthMessageHandled());
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
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(child: Divider(indent: 8, endIndent: 12)),
                            Text('или продолжить через'),
                            Expanded(child: Divider(indent: 12, endIndent: 8)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _handleGoogleLogin,
                          icon: Container(
                            height: 24,
                            width: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          label: const Text('Войти в demo-аккаунт'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE9E7F2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
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
