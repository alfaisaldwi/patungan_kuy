import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:patungan_kuy/core/onboarding/showcase_tour.dart';
import 'package:patungan_kuy/core/theme/theme_controller.dart';
import 'package:patungan_kuy/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'PatunganKuy',
      packageName: 'com.elumi.patungankuy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('default terang, pilihan tema tersimpan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.init();
    expect(ThemeController.mode.value, ThemeMode.light);
    expect(ThemeController.isDark.value, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(ThemeController.isDark.value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(find.text('Versi 1.0.0 (1)'), findsOneWidget);

    await ThemeController.setMode(ThemeMode.light);
  });

  testWidgets('pilihan lama is_dark_mode tetap terbaca', (tester) async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    await ThemeController.init();
    expect(ThemeController.mode.value, ThemeMode.dark);
    await ThemeController.setMode(ThemeMode.light);
  });

  testWidgets('ulangi tur menghapus status tur', (tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_showcase': true,
      'has_seen_assignment_showcase': true,
    });
    ShowcaseTour.register();
    addTearDown(() => ShowcaseView.get().unregister());

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ulangi tur aplikasi'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_showcase'), isNull);
    expect(prefs.getBool('has_seen_assignment_showcase'), isNull);
    expect(find.byType(SettingsPage), findsNothing);

    await tester.pump(const Duration(seconds: 1));
  });
}
