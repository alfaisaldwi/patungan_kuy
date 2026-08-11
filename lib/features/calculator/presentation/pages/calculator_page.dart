import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../injection_container.dart';
import '../../../assignment/presentation/models/assignment_result.dart';
import '../../../assignment/presentation/pages/assignment_page.dart';
import '../../../scanner/presentation/bloc/scanner_bloc.dart';
import '../bloc/calculator_bloc.dart';
import '../widgets/add_person_form.dart';
import '../widgets/order_list.dart';
import 'summary_page.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalculatorBloc>.value(value: sl<CalculatorBloc>()),
        BlocProvider<ScannerBloc>.value(value: sl<ScannerBloc>()),
      ],
      child: const _CalculatorView(),
    );
  }
}

class _CalculatorView extends StatefulWidget {
  const _CalculatorView();

  @override
  State<_CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<_CalculatorView> {
  final _addPersonFormKey = GlobalKey<AddPersonFormState>();

  void _expandAddPersonForm() => _addPersonFormKey.currentState?.expand();

  void _confirmReset() {
    final state = context.read<CalculatorBloc>().state;
    if (state.orders.isEmpty && state.result == null) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Semua?', style: AppTheme.heading3),
        content: Text(
          state.orders.isNotEmpty
              ? 'Semua pesanan (${state.orders.length} orang) dan hasil hitungan akan dihapus.'
              : 'Hasil hitungan akan dihapus.',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<CalculatorBloc>().add(const ResetCalculator());
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _openSummary() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const SummaryPage()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: _onScannerStateChanged,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage, vertical: AppTheme.spaceLg),
            child: BlocBuilder<CalculatorBloc, CalculatorState>(
              buildWhen: (prev, curr) => prev.orders.isEmpty != curr.orders.isEmpty,
              builder: (context, state) {
                final hasOrders = state.orders.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CalculatorHeader(onReset: _confirmReset),
                    const SizedBox(height: AppTheme.space2xl),
                    if (hasOrders) ...[
                      _SectionHeader(
                        icon: Icons.groups_rounded,
                        iconBg: AppTheme.primaryLight,
                        iconColor: AppTheme.primary,
                        title: 'Pesanan',
                        subtitle: 'Siapa aja yang ikut patungan',
                        trailing: const OrdersCountBadge(),
                      ),
                      const SizedBox(height: AppTheme.spaceLg),
                    ],
                    OrderList(onAddManually: _expandAddPersonForm),
                    const SizedBox(height: AppTheme.spaceMd),
                    if (hasOrders) ...[
                      AddPersonForm(key: _addPersonFormKey),
                      const SizedBox(height: AppTheme.space2xl),
                      _ContinueButton(onTap: _openSummary),
                    ],
                    const SizedBox(height: AppTheme.space2xl),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onScannerStateChanged(BuildContext context, ScannerState state) {
    if (state.status == ScannerStatus.success && state.parsedReceipt != null) {
      Navigator.of(context, rootNavigator: true)
          .push<AssignmentResult>(MaterialPageRoute(builder: (_) => AssignmentPage(receipt: state.parsedReceipt!)))
          .then((result) {
            if (result != null && mounted) {
              _applyAssignmentResult(context, result);
            }
          });
    }
    if (state.status == ScannerStatus.error && state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.error));
    }
  }

  void _applyAssignmentResult(BuildContext context, AssignmentResult result) {
    final calc = context.read<CalculatorBloc>();
    for (final order in result.orders) {
      calc.add(AddPersonOrder(name: order.name, items: order.items));
    }
    if (result.tax != null || result.deliveryFee != null || result.discount != null) {
      calc.add(
        UpdateFeesAndDiscount(
          taxFee: result.tax ?? 0,
          deliveryFee: result.deliveryFee ?? 0,
          discountAmount: result.discount ?? 0,
          isDiscountPercentage: false,
        ),
      );
    }
    calc.add(const CalculateBillEvent());
    final total = result.orders.fold<int>(0, (s, o) => s + o.items.length);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${result.orders.length} orang dengan $total item berhasil ditambahkan.')));
  }
}

class _CalculatorHeader extends StatelessWidget {
  final VoidCallback onReset;
  const _CalculatorHeader({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.textSecondary,
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppTheme.primaryGradient),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppTheme.shadowSm],
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hitung Patungan', style: AppTheme.heading3, maxLines: 1, overflow: TextOverflow.ellipsis),
              BlocBuilder<CalculatorBloc, CalculatorState>(
                builder: (context, state) {
                  final subtitle = state.orders.isEmpty
                      ? 'Yuk, mulai tambahin pesanan'
                      : '${state.orders.length} orang siap dibagi';
                  return Text(subtitle, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis);
                },
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppTheme.isDark ? 'Mode terang' : 'Mode gelap',
          onPressed: ThemeController.toggle,
          icon: Icon(AppTheme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          color: AppTheme.textSecondary,
        ),
        BlocBuilder<CalculatorBloc, CalculatorState>(
          builder: (context, state) {
            final hasData = state.orders.isNotEmpty || state.result != null;
            return IconButton(
              tooltip: 'Reset',
              onPressed: hasData ? onReset : null,
              icon: const Icon(Icons.refresh_rounded),
              color: hasData ? AppTheme.textSecondary : AppTheme.disabledText,
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.heading3),
              if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: AppTheme.bodySmall)],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final hasResult = state.status == CalculatorStatus.calculated && state.result != null;
        return SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.orders.isEmpty ? null : onTap,
            icon: Icon(hasResult ? Icons.receipt_long_rounded : Icons.arrow_forward_rounded, size: 20),
            label: Text(
              hasResult
                  ? 'Lihat Ringkasan · ${AppTheme.formatRupiah(state.result!.grandTotal)}'
                  : 'Lanjut ke Ringkasan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
