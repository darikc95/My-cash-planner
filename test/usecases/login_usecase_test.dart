// Тесты: LoginUseCase — успешный вход и неверный пароль

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:template/domain/entities/user.dart';
import 'package:template/domain/repositories/auth_repository.dart';
import 'package:template/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase loginUseCase;

  final testUser = User(
    id: 1,
    email: 'test@example.com',
    name: 'Тестовый Пользователь',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('успешный вход возвращает User при верных данных', () async {
      when(
        () => mockRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => testUser);

      final result = await loginUseCase(
        const LoginParams(
          email: 'test@example.com',
          password: 'password123',
        ),
      );

      expect(result, equals(testUser));
      verify(
        () => mockRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('выбрасывает исключение при неверном пароле', () async {
      when(
        () => mockRepository.login(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(Exception('Неверный пароль'));

      expect(
        () => loginUseCase(
          const LoginParams(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
