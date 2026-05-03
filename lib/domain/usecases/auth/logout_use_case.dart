import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() {
    return _authRepository.logout();
  }
}
