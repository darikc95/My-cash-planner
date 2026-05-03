import '../entities/auth_action_result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  User? getCurrentUser();

  bool get isAuthenticated;

  Future<AuthActionResult> register({
    required String email,
    required String password,
  });

  Future<AuthActionResult> login({
    required String email,
    required String password,
  });

  Future<AuthActionResult> resetPassword({
    required String email,
    required String newPassword,
  });

  Future<AuthActionResult> updateProfile({
    required String userId,
    required String name,
  });

  Future<AuthActionResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}
