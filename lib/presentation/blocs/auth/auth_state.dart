part of 'auth_bloc.dart';

enum AuthFlowAction {
  loggedIn,
  registered,
  loggedOut,
}

class AuthState extends Equatable {
  const AuthState({
    this.currentUser,
    this.isSubmitting = false,
    this.errorMessage,
    this.flowAction,
  });

  final User? currentUser;
  final bool isSubmitting;
  final String? errorMessage;
  final AuthFlowAction? flowAction;

  AuthState copyWith({
    Object? currentUser = _sentinel,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? flowAction = _sentinel,
  }) {
    return AuthState(
      currentUser:
          currentUser == _sentinel ? this.currentUser : currentUser as User?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      flowAction: flowAction == _sentinel
          ? this.flowAction
          : flowAction as AuthFlowAction?,
    );
  }

  @override
  List<Object?> get props =>
      [currentUser, isSubmitting, errorMessage, flowAction];
}

const _sentinel = Object();
