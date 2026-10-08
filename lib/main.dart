import 'package:flutter/material.dart';

import 'core/onboarding/showcase_tour.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await ThemeController.init();
  runApp(const PatunganKuyApp());
}

class PatunganKuyApp extends StatefulWidget {
  const PatunganKuyApp({super.key});

  @override
  State<PatunganKuyApp> createState() => _PatunganKuyAppState();
}

class _PatunganKuyAppState extends State<PatunganKuyApp> {
  bool _homeReady = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    ShowcaseTour.register();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'PatunganKuy',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(isDark),
          home: Stack(
            fit: StackFit.expand,
            children: [
              if (_homeReady)
                KeyedSubtree(key: ValueKey(isDark), child: const HomePage()),
              if (!_splashDone)
                SplashPage(
                  key: const ValueKey('splash'),
                  onReveal: () => setState(() => _homeReady = true),
                  onFinished: () => setState(() => _splashDone = true),
                ),
            ],
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        primary: AppTheme.primary,
        secondary: AppTheme.accent,
        surface: AppTheme.surface,
        error: AppTheme.error,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: AppTheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTheme.heading3,
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppTheme.primaryButton,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppTheme.outlinedButton,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
      ),
    );
  }
}
