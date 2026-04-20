// Слой: domain | Назначение: use case проверки сохранённой сессии при старте приложения

import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import 'base_usecase.dart';

class CheckSessionUseCase implements UseCase<User?, NoParams> {
  CheckSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<User?> call(NoParams params) {
    return _repository.checkSession();
  }
}
