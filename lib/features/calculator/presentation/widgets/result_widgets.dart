import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/calculator_bloc.dart';
import '../utils/receipt_image_generator.dart';
import 'receipt_image_view.dart';


class ResultSummaryBar extends StatelessWidget {
  final VoidCallback onView;
  const ResultSummaryBar({super.key, required this.onView});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final Widget child;
        if (state.status != CalculatorStatus.calculated ||
            state.result == null) {
          child = const SafeArea(
            top: false,
            child: SizedBox(width: double.infinity),
          );
        } else {
          child = Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
              boxShadow: [AppTheme.shadowMd],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingPage,
                  vertical: AppTheme.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Bayar', style: AppTheme.bodySmall),
                          Text(
                            AppTheme.formatRupiah(state.result!.grandTotal),
                            style: AppTheme.price,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Lihat Hasil'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
    );
  }
}

class ResultSheet extends StatefulWidget {
  const ResultSheet({super.key});

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  bool _isSharing = false;

  Future<void> _onShare() async {
    if (_isSharing) return;
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null) return;
    setState(() => _isSharing = true);
    try {
      await ReceiptImageGenerator.shareReceipt(
        context: context,
        result: state.result!,
        orders: state.orders,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
              child: BlocBuilder<CalculatorBloc, CalculatorState>(
                builder: (context, state) {
                  if (state.status != CalculatorStatus.calculated ||
                      state.result == null) {
                    return const SizedBox.shrink();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) => ReceiptImageView(
                      result: state.result!,
                      orders: state.orders,
                      width: constraints.maxWidth,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.paddingPage,
              0,
              AppTheme.paddingPage,
              AppTheme.spaceXl,
            ),
            child: _ReceiptActions(isSharing: _isSharing, onShare: _onShare),
          ),
        ],
      ),
    );
  }
}

class _ReceiptActions extends StatelessWidget {
  final bool isSharing;
  final VoidCallback onShare;
  const _ReceiptActions({required this.isSharing, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        if (state.status != CalculatorStatus.calculated) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isSharing ? null : onShare,
            icon: isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.image_rounded, size: 20),
            label: Text(
              isSharing ? 'Bentar ya...' : 'Bagikan Struk (Gambar)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
