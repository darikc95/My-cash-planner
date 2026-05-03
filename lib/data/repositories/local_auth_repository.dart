import '../../domain/entities/auth_action_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_service.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository(this._authService);

  final LocalAuthService _authService;

  @override
  User? getCurrentUser() => _authService.getCurrentUser();

  @override
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  Future<AuthActionResult> register({
    required String email,
    required String password,
  }) {
    return _authService.register(email: email, password: password);
  }

  @override
  Future<AuthActionResult> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  @override
  Future<AuthActionResult> resetPassword({
    required String email,
    required String newPassword,
  }) {
    return _authService.resetPassword(email: email, newPassword: newPassword);
  }

  @override
  Future<AuthActionResult> updateProfile({
    required String userId,
    required String name,
  }) {
    return _authService.updateProfile(userId: userId, name: name);
  }

  @override
  Future<AuthActionResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _authService.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> logout() => _authService.logout();
}
