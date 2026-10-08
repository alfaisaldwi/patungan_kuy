import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController {
  ThemeController._();

  static const String _modeKey = 'theme_mode';

  static const String _legacyKey = 'is_dark_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static bool _observing = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    final legacy = prefs.getBool(_legacyKey);
    mode.value =
        ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        (legacy == true ? ThemeMode.dark : ThemeMode.light);

    if (!_observing) {
      WidgetsBinding.instance.addObserver(_SystemBrightnessObserver());
      _observing = true;
    }
    _refresh();
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    _refresh();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, value.name);
  }

  static bool get _systemIsDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  static void _refresh() {
    final dark = switch (mode.value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => _systemIsDark,
    };
    AppTheme.setDark(dark);
    isDark.value = dark;
  }
}

class _SystemBrightnessObserver with WidgetsBindingObserver {
  @override
  void didChangePlatformBrightness() {
    if (ThemeController.mode.value == ThemeMode.system) {
      ThemeController._refresh();
    }
  }
}
