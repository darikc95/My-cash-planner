import '../../../data/datasources/local_auth_service.dart';

class LoginUseCase {
  const LoginUseCase(this._authService);

  final LocalAuthService _authService;

  Future<AuthActionResult> call({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }
}
