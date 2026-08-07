import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../calculator/presentation/bloc/calculator_bloc.dart';
import '../../../calculator/presentation/pages/calculator_page.dart';
import '../../../history/domain/entities/bill_history.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../scanner/presentation/bloc/scanner_bloc.dart';
import '../widgets/floating_nav_bar.dart';

class HomePage extends StatefulWidget {
  final CalculatorStartAction? startAction;
  final int initialTab;

  const HomePage({super.key, this.startAction, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _controller = PersistentTabController(
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryEntry(BillHistory entry) async {
    final calc = sl<CalculatorBloc>();

    if (calc.state.orders.isNotEmpty || calc.state.result != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Muat dari Riwayat?', style: AppTheme.heading3),
          content: Text(
            'Tagihan ini akan menggantikan ${calc.state.orders.length} pesanan yang lagi kamu isi sekarang.',
            style: AppTheme.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    calc.add(RestoreFromHistory(entry: entry));
    _controller.jumpToTab(0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tagihan ${entry.orders.length} orang berhasil dimuat dari riwayat.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return MultiBlocProvider(
      providers: [
        BlocProvider<CalculatorBloc>.value(value: sl<CalculatorBloc>()),
        BlocProvider<ScannerBloc>.value(value: sl<ScannerBloc>()),
      ],
      child: PersistentTabView(
        controller: _controller,
        tabs: [
          PersistentTabConfig(
            screen: CalculatorPage(startAction: widget.startAction),
            item: ItemConfig(
              icon: const Icon(Icons.home_rounded),
              title: 'Beranda',
              textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
              activeForegroundColor: AppTheme.primary,
              inactiveForegroundColor: AppTheme.disabledText,
              iconSize: 28,
            ),
          ),
          PersistentTabConfig(
            screen: HistoryPage(onLoadToCalculator: _loadHistoryEntry),
            item: ItemConfig(
              icon: const Icon(Icons.history),
              title: 'Riwayat',
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              activeForegroundColor: AppTheme.primary,
              inactiveForegroundColor: AppTheme.disabledText,
              iconSize: 28,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) =>
            FloatingNavBar(navBarConfig: navBarConfig),
        navBarOverlap: const NavBarOverlap.full(),
        margin: EdgeInsets.fromLTRB(80, 0, 80, bottomInset + 8),
        stateManagement: true,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
