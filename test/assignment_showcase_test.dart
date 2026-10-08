import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/core/onboarding/showcase_tour.dart';
import 'package:patungan_kuy/features/assignment/presentation/pages/assignment_page.dart';
import 'package:patungan_kuy/features/calculator/domain/entities/person_order.dart';
import 'package:patungan_kuy/features/scanner/domain/entities/parsed_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

const _receipt = ParsedReceipt(
  orders: [
    ExtractedOrder(
      name: 'Pesanan',
      items: [
        OrderItem(name: 'Nasi Goreng', price: 25000),
        OrderItem(name: 'Es Teh', price: 8000),
      ],
    ),
  ],
);

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
  const MaterialApp(home: AssignmentPage(receipt: _receipt)),
);

void main() {
  testWidgets('pertama kali buka halaman bagi-bagi: tur tampil & tersimpan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester);

    final view = ShowcaseView.getNamed(ShowcaseTour.assignmentScope);
    expect(view.isShowcaseRunning, isFalse);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 600));
    expect(view.isShowcaseRunning, isTrue);

    view.dismiss();
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_assignment_showcase'), isTrue);
    expect(prefs.getBool('has_seen_showcase'), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sudah pernah lihat: tur bagi-bagi tidak tampil', (tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_assignment_showcase': true,
    });
    await _pump(tester);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      ShowcaseView.getNamed(ShowcaseTour.assignmentScope).isShowcaseRunning,
      isFalse,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
