// Слой: data | Назначение: реализация AuthRepository через локальные источники данных

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._localDatasource);

  final AuthLocalDatasource _localDatasource;

  @override
  Future<User> login({required String email, required String password}) async {
    final user = await _localDatasource.login(email: email, password: password);
    await _localDatasource.saveSession(user);
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _localDatasource.register(
      name: name,
      email: email,
      password: password,
    );
    await _localDatasource.saveSession(user);
    return user;
  }

  @override
  Future<User?> checkSession() {
    return _localDatasource.loadSession();
  }

  @override
  Future<void> logout() {
    return _localDatasource.clearSession();
  }
}
