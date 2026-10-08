import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:patungan_kuy/injection_container.dart';
import 'package:patungan_kuy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_seen_showcase': true});
    await GetIt.instance.reset();
    await initDependencies();
  });

  tearDown(() => ShowcaseView.get().unregister());

  testWidgets('splash lalu beranda tampil', (tester) async {
    await tester.pumpWidget(const PatunganKuyApp());

    expect(find.text('Hitung Patungan'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hitung Patungan'), findsOneWidget);
    expect(find.text('Scan Struk'), findsOneWidget);
    expect(find.text('Tulis Manual'), findsOneWidget);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
