import '../../../data/datasources/local_auth_service.dart';
import '../../entities/user.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._authService);

  final LocalAuthService _authService;

  User? call() {
    return _authService.getCurrentUser();
  }
}
