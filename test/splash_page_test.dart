import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('splash memanggil onReveal lalu onFinished dalam ~3 detik', (
    tester,
  ) async {
    var revealed = false;
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          onReveal: () => revealed = true,
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(find.text('Patungan? Kuy!'), findsNothing);
    expect(revealed, isFalse);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(revealed, isTrue);
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 600));
    expect(finished, isTrue);
  });
}
