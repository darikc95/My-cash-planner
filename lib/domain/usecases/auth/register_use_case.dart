import '../../../data/datasources/local_auth_service.dart';

class RegisterUseCase {
  const RegisterUseCase(this._authService);

  final LocalAuthService _authService;

  Future<AuthActionResult> call({
    required String email,
    required String password,
  }) {
    return _authService.register(email: email, password: password);
  }
}
