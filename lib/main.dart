import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/calculator/presentation/pages/calculator_page.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await ThemeController.init();
  runApp(const PatunganKuyApp());
}

class PatunganKuyApp extends StatelessWidget {
  const PatunganKuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'PatunganKuy',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(isDark),
          // Re-inflate the whole tree on toggle so widgets reading AppTheme
          // getters pick up the new palette. Bloc state survives because the
          // blocs are app-lifetime singletons provided via BlocProvider.value.
          home: KeyedSubtree(key: ValueKey(isDark), child: const CalculatorPage()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppTheme.primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppTheme.outlinedButton),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        ),
      ),
    );
  }
}
