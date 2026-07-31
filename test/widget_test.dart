import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:patungan_kuy/injection_container.dart';
import 'package:patungan_kuy/main.dart';

void main() {
  setUp(() async {
    // Reset DI before each test to ensure clean state.
    await GetIt.instance.reset();
    await initDependencies();
  });

  testWidgets('PatunganKuy smoke test — app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const PatunganKuyApp());
    await tester.pumpAndSettle();

    // Verify the app bar title is displayed.
    expect(find.text('PatunganKuy'), findsOneWidget);

    // Verify the "Add Person" section is present.
    expect(find.text('Add Person'), findsOneWidget);

    // Verify the "Add" button exists.
    expect(find.text('Add'), findsOneWidget);

    // Verify the calculate button is present (disabled initially since no orders).
    expect(find.text('Calculate Split'), findsOneWidget);

    // Verify the empty state message.
    expect(find.text('No orders yet. Add someone above.'), findsOneWidget);
  });
}
