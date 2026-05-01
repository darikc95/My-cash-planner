import 'package:flutter/material.dart';

abstract final class AppThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static ThemeMode fromStorage(String raw) {
    return raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static String toStorage(ThemeMode mode) {
    return mode == ThemeMode.dark ? 'dark' : 'light';
  }
}
