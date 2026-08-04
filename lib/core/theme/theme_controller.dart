import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController {
  ThemeController._();

  static const String _prefKey = 'is_dark_mode';

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_prefKey) ?? false;
    AppTheme.setDark(dark);
    isDark.value = dark;
  }

  static Future<void> toggle() async {
    final dark = !isDark.value;
    AppTheme.setDark(dark);
    isDark.value = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, dark);
  }
}
