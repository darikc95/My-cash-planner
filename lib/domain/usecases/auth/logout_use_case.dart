import '../../../data/datasources/local_auth_service.dart';

class LogoutUseCase {
  const LogoutUseCase(this._authService);

  final LocalAuthService _authService;

  Future<void> call() {
    return _authService.logout();
  }
}
