import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/calculator/presentation/pages/calculator_page.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const PatunganKuyApp());
}

class PatunganKuyApp extends StatelessWidget {
  const PatunganKuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PatunganKuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.accent,
          surface: AppTheme.surface,
          error: AppTheme.error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: const AppBarTheme(
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
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.border),
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
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: AppTheme.primaryButton),
        outlinedButtonTheme: OutlinedButtonThemeData(style: AppTheme.outlinedButton),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}
