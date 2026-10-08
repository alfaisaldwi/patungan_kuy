import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patungan_kuy/features/assignment/presentation/bloc/assignment_bloc.dart';
import 'package:patungan_kuy/features/assignment/presentation/pages/assignment_page.dart';
import 'package:patungan_kuy/features/calculator/domain/entities/person_order.dart';
import 'package:patungan_kuy/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:patungan_kuy/features/calculator/presentation/pages/summary_page.dart';
import 'package:patungan_kuy/features/scanner/domain/entities/parsed_receipt.dart';
import 'package:patungan_kuy/features/settings/presentation/pages/settings_page.dart';
import 'package:patungan_kuy/injection_container.dart';
import 'package:patungan_kuy/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _receipt = ParsedReceipt(
  orders: [
    ExtractedOrder(
      name: 'Pesanan',
      items: [
        OrderItem(name: 'Nasi Goreng Spesial', price: 32000),
        OrderItem(name: 'Ayam Geprek Sambal Matah', price: 28000),
        OrderItem(name: '3x Es Teh Manis', price: 15000),
        OrderItem(name: 'Kentang Goreng', price: 18000),
        OrderItem(name: 'Kerupuk', price: 4000),
      ],
    ),
  ],
  detectedSubtotal: 97000,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  }

  NavigatorState rootNavigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator).first);

  testWidgets('screenshots README', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_showcase', true);
    await prefs.setBool('has_seen_assignment_showcase', true);
    await prefs.setString('theme_mode', 'light');

    app.main();
    await wait(tester, 8000);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await wait(tester, 300);
    }
    await binding.takeScreenshot('home');

    rootNavigator(tester).push(
      MaterialPageRoute(builder: (_) => const AssignmentPage(receipt: _receipt)),
    );
    await wait(tester, 900);
    final bloc = BlocProvider.of<ReceiptAssignmentBloc>(
      tester.element(find.text('Bagi-bagi Item')),
    );
    for (final name in ['Adam', 'Siti', 'Bima']) {
      bloc.add(AddPerson(name: name));
    }
    await wait(tester, 300);
    final p = bloc.state.persons;
    final items = bloc.state.items;
    bloc.add(SplitScannedItem(itemId: items[2].id, parts: 3));
    await wait(tester, 300);
    final it = bloc.state.items;
    void give(int item, int person) => bloc.add(
      ToggleItemAssignment(itemId: it[item].id, personId: p[person].id),
    );
    give(0, 0);
    give(1, 1);
    give(2, 0);
    give(3, 1);
    give(4, 2);
    give(5, 0);
    give(5, 1);
    give(5, 2);
    await wait(tester, 800);
    await binding.takeScreenshot('assignment');

    rootNavigator(tester).pop();
    await wait(tester, 600);

    sl<CalculatorBloc>()
      ..add(
        const AddPersonOrder(
          name: 'Adam',
          items: [
            OrderItem(name: 'Nasi Goreng Spesial', price: 32000),
            OrderItem(name: 'Es Teh Manis', price: 5000),
          ],
        ),
      )
      ..add(
        const AddPersonOrder(
          name: 'Siti',
          items: [
            OrderItem(name: 'Ayam Geprek Sambal Matah', price: 28000),
            OrderItem(name: 'Es Teh Manis', price: 5000),
          ],
        ),
      )
      ..add(
        const AddPersonOrder(
          name: 'Bima',
          items: [
            OrderItem(name: 'Es Teh Manis', price: 5000),
            OrderItem(name: 'Kentang Goreng', price: 18000),
          ],
        ),
      )
      ..add(
        const UpdateFeesAndDiscount(
          taxFee: 9300,
          deliveryFee: 12000,
          discountAmount: 15000,
          isDiscountPercentage: false,
        ),
      );
    await wait(tester, 500);

    rootNavigator(tester).push(
      MaterialPageRoute(builder: (_) => const SummaryPage()),
    );
    await wait(tester, 900);
    await tester.tap(find.text('Hitung Patungan').last);
    await wait(tester, 1500);
    await binding.takeScreenshot('result');

    rootNavigator(tester).pop();
    await wait(tester, 500);
    rootNavigator(tester).pop();
    await wait(tester, 500);

    rootNavigator(tester).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    await wait(tester, 1200);
    await binding.takeScreenshot('settings');
  });
}
