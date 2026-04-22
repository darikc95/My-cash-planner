import '../entities/user.dart';

abstract interface class UserRepository {
  Future<void> saveUser(User user);

  Future<User?> getUserById(String userId);

  Future<List<User>> getAllUsers();

  Future<void> deleteUser(String userId);

  Future<void> clearUsers();
}
