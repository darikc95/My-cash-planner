import 'package:hive/hive.dart';

import '../../core/constants/hive_box_names.dart';
import '../../domain/entities/user.dart';
import 'hive_storage_service.dart';

class LocalAuthService {
  const LocalAuthService(this._storageService);

  static const _sessionUserIdKey = 'auth.current_user_id';
  static const _sessionEmailKey = 'auth.current_email';
  static const _currentUserKey = 'auth.current_user';

  final HiveStorageService _storageService;

  Box<dynamic> get _authBox => Hive.box<dynamic>(HiveBoxNames.auth);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(HiveBoxNames.settings);
  Box<dynamic> get _profileBox => Hive.box<dynamic>(HiveBoxNames.profile);

  String _passwordByUserIdKey(String userId) => 'auth.password.$userId';
  String _passwordByEmailKey(String email) => 'auth.password.email.$email';

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  User? _findUserByEmail(String email) {
    final normalizedEmail = _normalizeEmail(email);
    final users = _storageService.getAllUsers();

    for (final user in users) {
      if (_normalizeEmail(user.email) == normalizedEmail) {
        return user;
      }
    }

    return null;
  }

  User? getCurrentUser() {
    final currentUserId = (_authBox.get(_sessionUserIdKey) ??
        _settingsBox.get(_sessionUserIdKey)) as String?;

    if (currentUserId != null && currentUserId.isNotEmpty) {
      final userById = _storageService.getUserById(currentUserId);
      if (userById != null) {
        return userById;
      }
    }

    final currentEmail = _authBox.get(_sessionEmailKey) as String?;
    if (currentEmail == null || currentEmail.isEmpty) {
      return null;
    }

    return _findUserByEmail(currentEmail);
  }

  bool get isAuthenticated => getCurrentUser() != null;

  Future<AuthActionResult> register({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthActionResult.failure('Заполните email и пароль.');
    }

    if (_findUserByEmail(normalizedEmail) != null) {
      return const AuthActionResult.failure(
        'Пользователь с таким email уже существует.',
      );
    }

    final now = DateTime.now();
    final user = User(
      id: 'user_${now.microsecondsSinceEpoch}',
      email: normalizedEmail,
      name: normalizedEmail.split('@').first,
      createdAt: now,
    );

    await _storageService.saveUser(user);
    await _authBox.put(_passwordByEmailKey(normalizedEmail), password);
    await _authBox.put(_passwordByUserIdKey(user.id), password);
    await _settingsBox.put(_passwordByUserIdKey(user.id), password);
    await _saveSession(user);

    return AuthActionResult.success(user);
  }

  Future<AuthActionResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthActionResult.failure('Введите email и пароль.');
    }

    final user = _findUserByEmail(normalizedEmail);
    if (user == null) {
      return const AuthActionResult.failure(
        'Пользователь с таким email не найден.',
      );
    }

    final savedPassword = (_authBox.get(_passwordByEmailKey(normalizedEmail)) ??
        _authBox.get(_passwordByUserIdKey(user.id)) ??
        _settingsBox.get(_passwordByUserIdKey(user.id))) as String?;

    if (savedPassword != password) {
      return const AuthActionResult.failure('Неверный пароль.');
    }

    await _saveSession(user);
    return AuthActionResult.success(user);
  }

  Future<AuthActionResult> loginWithDemoAccount() async {
    const demoEmail = 'demo@mycashplanner.app';
    const demoPassword = 'demo12345';

    final existingUser = _findUserByEmail(demoEmail);
    if (existingUser == null) {
      final now = DateTime.now();
      final user = User(
        id: 'demo_user',
        email: demoEmail,
        name: 'Demo User',
        createdAt: now,
      );

      await _storageService.saveUser(user);
      await _authBox.put(_passwordByEmailKey(demoEmail), demoPassword);
      await _authBox.put(_passwordByUserIdKey(user.id), demoPassword);
      await _settingsBox.put(_passwordByUserIdKey(user.id), demoPassword);
      await _saveSession(user);
      return AuthActionResult.success(user);
    }

    return login(email: demoEmail, password: demoPassword);
  }

  Future<AuthActionResult> updateProfile({
    required String userId,
    required String name,
  }) async {
    final user = _storageService.getUserById(userId);
    if (user == null) {
      return const AuthActionResult.failure('Пользователь не найден.');
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const AuthActionResult.failure('Введите имя пользователя.');
    }

    final updatedUser = user.copyWith(name: normalizedName);
    await _storageService.saveUser(updatedUser);
    await _saveSession(updatedUser);
    return AuthActionResult.success(updatedUser);
  }

  Future<AuthActionResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _storageService.getUserById(userId);
    if (user == null) {
      return const AuthActionResult.failure('Пользователь не найден.');
    }

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return const AuthActionResult.failure(
          'Заполните текущий и новый пароль.');
    }

    if (newPassword.length < 6) {
      return const AuthActionResult.failure(
          'Новый пароль должен быть не короче 6 символов.');
    }

    final savedPassword = (_authBox.get(_passwordByEmailKey(user.email)) ??
        _authBox.get(_passwordByUserIdKey(user.id)) ??
        _settingsBox.get(_passwordByUserIdKey(user.id))) as String?;

    if (savedPassword != currentPassword) {
      return const AuthActionResult.failure('Текущий пароль введён неверно.');
    }

    await _savePassword(user: user, password: newPassword);
    await _saveSession(user);
    return AuthActionResult.success(user);
  }

  Future<AuthActionResult> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final user = _findUserByEmail(normalizedEmail);
    if (user == null) {
      return const AuthActionResult.failure(
        'Пользователь с таким email не найден.',
      );
    }

    if (newPassword.length < 6) {
      return const AuthActionResult.failure(
          'Пароль должен быть не короче 6 символов.');
    }

    await _savePassword(user: user, password: newPassword);
    return AuthActionResult.success(user);
  }

  Future<void> logout() async {
    await _authBox.delete(_sessionUserIdKey);
    await _authBox.delete(_sessionEmailKey);
    await _settingsBox.delete(_sessionUserIdKey);
    await _profileBox.delete(_currentUserKey);
  }

  Future<void> _saveSession(User user) async {
    await _authBox.put(_sessionUserIdKey, user.id);
    await _authBox.put(_sessionEmailKey, user.email);
    await _settingsBox.put(_sessionUserIdKey, user.id);
    await _profileBox.put(_currentUserKey, user);
  }

  Future<void> _savePassword({
    required User user,
    required String password,
  }) async {
    await _authBox.put(_passwordByEmailKey(user.email), password);
    await _authBox.put(_passwordByUserIdKey(user.id), password);
    await _settingsBox.put(_passwordByUserIdKey(user.id), password);
  }
}

class AuthActionResult {
  const AuthActionResult._({
    required this.success,
    this.user,
    this.message,
  });

  const AuthActionResult.success(User user) : this._(success: true, user: user);

  const AuthActionResult.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final User? user;
  final String? message;
}
