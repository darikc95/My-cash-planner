import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth/get_current_user_use_case.dart';
import '../../../domain/usecases/auth/login_use_case.dart';
import '../../../domain/usecases/auth/logout_use_case.dart';
import '../../../domain/usecases/auth/register_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthState()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthMessageHandled>(_onMessageHandled);
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  void _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) {
    final user = _getCurrentUserUseCase();
    emit(
      state.copyWith(
        currentUser: user,
        errorMessage: null,
        flowAction: null,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        flowAction: null,
      ),
    );

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    if (!result.success || result.user == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: result.message ?? 'Ошибка входа.',
          flowAction: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        currentUser: result.user,
        errorMessage: null,
        flowAction: AuthFlowAction.loggedIn,
      ),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        flowAction: null,
      ),
    );

    final result = await _registerUseCase(
      email: event.email,
      password: event.password,
    );

    if (!result.success || result.user == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: result.message ?? 'Ошибка регистрации.',
          flowAction: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: false,
        currentUser: result.user,
        errorMessage: null,
        flowAction: AuthFlowAction.registered,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        flowAction: null,
      ),
    );

    await _logoutUseCase();

    emit(
      state.copyWith(
        isSubmitting: false,
        currentUser: null,
        errorMessage: null,
        flowAction: AuthFlowAction.loggedOut,
      ),
    );
  }

  void _onMessageHandled(
    AuthMessageHandled event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: null,
        flowAction: null,
      ),
    );
  }
}
