import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Tema mengikuti setting sistem sampai user memilih manual lewat [toggle];
/// setelah itu pilihan user yang dipakai dan disimpan.
class ThemeController {
  ThemeController._();

  static const String _prefKey = 'is_dark_mode';

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static bool _userOverride = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey);
    _userOverride = saved != null;
    _apply(saved ?? _systemIsDark);

    WidgetsBinding.instance.addObserver(_SystemBrightnessObserver());
  }

  static Future<void> toggle() async {
    _userOverride = true;
    _apply(!isDark.value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isDark.value);
  }

  static bool get _systemIsDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  static void _apply(bool dark) {
    AppTheme.setDark(dark);
    isDark.value = dark;
  }

  static void _onSystemBrightnessChanged() {
    if (_userOverride) return;
    _apply(_systemIsDark);
  }
}

class _SystemBrightnessObserver with WidgetsBindingObserver {
  @override
  void didChangePlatformBrightness() =>
      ThemeController._onSystemBrightnessChanged();
}
