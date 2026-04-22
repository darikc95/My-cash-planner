import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/hive_storage_service.dart';

class HiveUserRepository implements UserRepository {
  const HiveUserRepository(this._storageService);

  final HiveStorageService _storageService;

  @override
  Future<void> saveUser(User user) {
    return _storageService.saveUser(user);
  }

  @override
  Future<User?> getUserById(String userId) {
    return Future.value(_storageService.getUserById(userId));
  }

  @override
  Future<List<User>> getAllUsers() {
    return Future.value(_storageService.getAllUsers());
  }

  @override
  Future<void> deleteUser(String userId) {
    return _storageService.deleteUser(userId);
  }

  @override
  Future<void> clearUsers() {
    return _storageService.clearUsers();
  }
}
