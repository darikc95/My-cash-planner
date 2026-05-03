import '../../entities/auth_action_result.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthActionResult> call({
    required String email,
    required String password,
  }) {
    return _authRepository.register(email: email, password: password);
  }
}
