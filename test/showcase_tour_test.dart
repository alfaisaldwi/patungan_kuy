import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:patungan_kuy/core/onboarding/showcase_tour.dart';
import 'package:patungan_kuy/features/home/presentation/pages/home_page.dart';
import 'package:patungan_kuy/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  ShowcaseTour.register();
  await tester.pumpWidget(const MaterialApp(home: HomePage()));
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    await initDependencies();
  });

  tearDown(() => ShowcaseView.get().unregister());

  testWidgets('pertama kali buka: tur tampil dan status tersimpan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpHome(tester);

    expect(ShowcaseView.get().isShowcaseRunning, isFalse);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));
    expect(ShowcaseView.get().isShowcaseRunning, isTrue);

    ShowcaseView.get().dismiss();
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_showcase'), isTrue);
  });

  testWidgets('sudah pernah lihat: tur tidak tampil lagi', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_showcase': true});
    await _pumpHome(tester);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 600));
    expect(ShowcaseView.get().isShowcaseRunning, isFalse);
  });
}
