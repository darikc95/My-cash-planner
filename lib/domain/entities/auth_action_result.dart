import 'user.dart';

class AuthActionResult {
  const AuthActionResult._({
    required this.success,
    this.user,
    this.message,
  });

  const AuthActionResult.success(User user) : this._(success: true, user: user);

  const AuthActionResult.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final User? user;
  final String? message;
}
