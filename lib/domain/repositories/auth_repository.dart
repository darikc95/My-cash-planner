// Слой: domain | Назначение: абстрактный интерфейс репозитория авторизации

import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  Future<User?> checkSession();

  Future<void> logout();
}
