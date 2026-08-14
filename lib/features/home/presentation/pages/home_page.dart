import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int initialTab;

  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _BottomSheetVisibilityObserver extends NavigatorObserver {
  _BottomSheetVisibilityObserver(this._openSheetCount);

  final ValueNotifier<int> _openSheetCount;

  void _update(Route route, int delta) {
    if (route is ModalBottomSheetRoute) {
      _openSheetCount.value += delta;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) => _update(route, 1);

  @override
  void didPop(Route route, Route? previousRoute) => _update(route, -1);

  @override
  void didRemove(Route route, Route? previousRoute) => _update(route, -1);
}

class _HomePageState extends State<HomePage> {
  late final _controller = PersistentTabController(
    initialIndex: widget.initialTab,
  );
  final _openSheetCount = ValueNotifier<int>(0);
  late final _calculatorTabSheetObserver =
      _BottomSheetVisibilityObserver(_openSheetCount);
  late final _historyTabSheetObserver =
      _BottomSheetVisibilityObserver(_openSheetCount);

  static const _homeTabIndex = 0;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _controller.dispose();
    _openSheetCount.dispose();
    super.dispose();
  }

  Future<void> _handleBackPress() async {
    if (_controller.index != _homeTabIndex) {
      _controller.jumpToTab(_homeTabIndex);
      return;
    }

    final now = DateTime.now();
    final isSecondPress = _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2);

    if (isSecondPress) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressTime = now;
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tekan sekali lagi untuk keluar'),
        duration: Duration(seconds: 2),
      ),
    );
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalculatorBloc>.value(value: sl<CalculatorBloc>()),
        BlocProvider<ScannerBloc>.value(value: sl<ScannerBloc>()),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackPress();
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _openSheetCount,
          builder: (context, openSheetCount, _) => PersistentTabView(
            controller: _controller,
            handleAndroidBackButtonPress: false,
            hideNavigationBar: openSheetCount > 0,
            tabs: [
              PersistentTabConfig(
                screen: const CalculatorPage(),
                item: ItemConfig(
                  icon: const Icon(Icons.home_rounded),
                  title: 'Beranda',
                  textStyle:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  activeForegroundColor: AppTheme.primary,
                  inactiveForegroundColor: AppTheme.disabledText,
                  iconSize: 28,
                ),
                navigatorConfig: NavigatorConfig(
                  navigatorObservers: [_calculatorTabSheetObserver],
                ),
              ),
              PersistentTabConfig(
                screen: HistoryPage(onLoadToCalculator: _loadHistoryEntry),
                item: ItemConfig(
                  icon: const Icon(Icons.history),
                  title: 'Riwayat',
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  activeForegroundColor: AppTheme.primary,
                  inactiveForegroundColor: AppTheme.disabledText,
                  iconSize: 28,
                ),
                navigatorConfig: NavigatorConfig(
                  navigatorObservers: [_historyTabSheetObserver],
                ),
              ),
            ],
            navBarBuilder: (navBarConfig) =>
                FloatingNavBar(navBarConfig: navBarConfig),
            navBarOverlap: const NavBarOverlap.full(),
            margin: const EdgeInsets.fromLTRB(80, 0, 80, 8),
            stateManagement: true,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
