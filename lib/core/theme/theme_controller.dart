import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Default-nya mode terang. Setelah user memilih lewat [toggle], pilihannya
/// disimpan dan dipakai pada pembukaan berikutnya.
class ThemeController {
  ThemeController._();

  static const String _prefKey = 'is_dark_mode';

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apply(prefs.getBool(_prefKey) ?? false);
  }

  static Future<void> toggle() async {
    _apply(!isDark.value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isDark.value);
  }

  static void _apply(bool dark) {
    AppTheme.setDark(dark);
    isDark.value = dark;
  }
}
