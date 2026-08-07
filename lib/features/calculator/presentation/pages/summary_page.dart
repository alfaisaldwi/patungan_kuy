import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../bloc/calculator_bloc.dart';
import '../widgets/fees_discount_section.dart';
import '../widgets/result_widgets.dart';


class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalculatorBloc>.value(
      value: sl<CalculatorBloc>(),
      child: const _SummaryView(),
    );
  }
}

class _SummaryView extends StatefulWidget {
  const _SummaryView();

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<_SummaryView> {
  void _showResultSheet() {
    final calc = context.read<CalculatorBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) =>
          BlocProvider.value(value: calc, child: const ResultSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalculatorBloc, CalculatorState>(
      listenWhen: (prev, curr) =>
          curr.status == CalculatorStatus.calculated &&
          prev.status != CalculatorStatus.calculated &&
          curr.result != null,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResultSheet();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ringkasan Tagihan', style: AppTheme.heading3),
        ),
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingPage,
                    vertical: AppTheme.spaceLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(
                        icon: Icons.receipt_long_rounded,
                        iconBg: AppTheme.accentLight,
                        iconColor: AppTheme.accent,
                        title: 'Biaya & Diskon',
                        subtitle: 'Ongkir, pajak, dan promo kalau ada',
                      ),
                      const SizedBox(height: AppTheme.spaceLg),
                      const FeesDiscountSection(),
                      const SizedBox(height: AppTheme.space2xl),
                      const _CalculateButton(),
                      const SizedBox(height: AppTheme.spaceMd),
                      const _ErrorDisplay(),
                      const SizedBox(height: AppTheme.space2xl),
                    ],
                  ),
                ),
              ),
            ),
            ResultSummaryBar(onView: _showResultSheet),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.heading3),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(subtitle!, style: AppTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        return SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.orders.isEmpty
                ? null
                : () => context.read<CalculatorBloc>().add(
                    const CalculateBillEvent(),
                  ),
            icon: const Icon(Icons.calculate_outlined, size: 20),
            label: const Text(
              'Hitung Patungan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final hasError =
            state.status == CalculatorStatus.error &&
            state.errorMessage != null;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: !hasError
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('error'),
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
