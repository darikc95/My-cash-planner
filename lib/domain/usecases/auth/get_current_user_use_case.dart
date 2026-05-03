import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  User? call() {
    return _authRepository.getCurrentUser();
  }
}
