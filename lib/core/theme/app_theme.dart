import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void setDark(bool value) => _isDark = value;

  static const Color primary = Color(0xFFFF6B6B);

  static const Color primaryDark = Color(0xFFE05555);

  static const Color secondary = Color(0xFF2B3A4A);

  static const Color accent = Color(0xFF4ECDC4);

  static const Color white = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF40C057);
  static const Color warning = Color(0xFFFFA94D);
  static const Color error = Color(0xFFFF6B6B);

  static Color get primaryLight => _isDark ? const Color(0xFF3E2A2C) : const Color(0xFFFFE5E5);
  static Color get accentLight => _isDark ? const Color(0xFF1E3634) : const Color(0xFFE0F7F5);
  static Color get successLight => _isDark ? const Color(0xFF20352A) : const Color(0xFFD3F9D8);
  static Color get warningLight => _isDark ? const Color(0xFF3B3122) : const Color(0xFFFFF3E0);
  static Color get errorLight => _isDark ? const Color(0xFF3E2A2C) : const Color(0xFFFFE5E5);

  static Color get background => _isDark ? const Color(0xFF121417) : const Color(0xFFF8F9FA);
  static Color get surface => _isDark ? const Color(0xFF1D2025) : const Color(0xFFFFFFFF);
  static Color get border => _isDark ? const Color(0xFF2E333A) : const Color(0xFFE9ECEF);
  static Color get divider => _isDark ? const Color(0xFF272B31) : const Color(0xFFF1F3F5);

  static Color get textPrimary => _isDark ? const Color(0xFFF1F3F5) : const Color(0xFF212529);
  static Color get textSecondary => _isDark ? const Color(0xFFADB5BD) : const Color(0xFF6C757D);
  static Color get textHint => _isDark ? const Color(0xFF6C757D) : const Color(0xFFADB5BD);

  static Color get disabled => _isDark ? const Color(0xFF343A40) : const Color(0xFFDEE2E6);
  static Color get disabledText => _isDark ? const Color(0xFF6C757D) : const Color(0xFFADB5BD);

  static TextStyle get heading1 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary);

  static TextStyle get body => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5);

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textHint,
        letterSpacing: 0.3,
      );

  static TextStyle get label => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get price => TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary);

  static TextStyle get priceLarge => TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary);

  static String formatRupiah(num value) {
    final isNegative = value < 0;
    final absValue = value.abs();

    final parts = absValue.toString().split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    var result = buffer.toString();
    if (decimalPart.isNotEmpty) {
      final dec = decimalPart.length >= 2 ? decimalPart.substring(0, 2) : decimalPart.padRight(2, '0');
      result = '$result,$dec';
    }

    return '${isNegative ? "-" : ""}Rp $result';
  }

  static final TextInputFormatter rupiahFormatter = _RupiahInputFormatter();

  static double parseRupiah(String formatted) {
    if (formatted.isEmpty) return 0.0;
    var s = formatted.replaceAll('Rp', '').replaceAll('rp', '').replaceAll(' ', '').trim();

    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else if (s.contains(',') && !s.contains('.')) {
      final after = s.split(',').last;
      if (after.length <= 2) {
        s = s.replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else {
      s = s.replaceAll('.', '');
    }
    return double.tryParse(s) ?? 0.0;
  }

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  static const double paddingPage = 20;
  static const double paddingCard = 16;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  static BoxShadow get shadowSm => BoxShadow(
        color: Colors.black.withAlpha(_isDark ? 40 : 8),
        blurRadius: 4,
        offset: const Offset(0, 1),
      );

  static BoxShadow get shadowMd => BoxShadow(
        color: Colors.black.withAlpha(_isDark ? 50 : 10),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow get shadowLg => BoxShadow(
        color: Colors.black.withAlpha(_isDark ? 60 : 12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error),
      ),
      labelStyle: bodySmall,
      hintStyle: TextStyle(color: textHint, fontSize: 14),
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        disabledBackgroundColor: disabled,
        disabledForegroundColor: disabledText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static ButtonStyle get chipButton => ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: [shadowSm],
      );

  static BoxDecoration get cardElevated => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: [shadowMd],
      );
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    var raw = newValue.text.replaceAll(RegExp(r'[Rp\s\.]'), '');

    if (raw.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));

    final digitsOnly = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && (digitsOnly.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = 'Rp ${buffer.toString()}';

    final offsetDelta = formatted.length - newValue.text.length;
    final newOffset = (newValue.selection.baseOffset + offsetDelta).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
