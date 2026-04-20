// Слой: core | Назначение: валидаторы для форм

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Некорректный формат email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < AppConstants.kMinPasswordLength) {
      return 'Минимум ${AppConstants.kMinPasswordLength} символов';
    }
    return null;
  }

  static String? requiredField(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно для заполнения';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return 'Пароли не совпадают';
    }
    return null;
  }
}
