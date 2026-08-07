import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/calculated_bill.dart';
import '../bloc/calculator_bloc.dart';
import '../utils/receipt_image_generator.dart';
import '../utils/receipt_pdf_generator.dart';


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
  final _receiptKey = GlobalKey();
  bool _isSharing = false;
  bool _isExporting = false;

  Future<void> _onShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ReceiptImageGenerator.captureAndShare(
        context: context,
        repaintKey: _receiptKey,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _onExportPdf() async {
    if (_isExporting) return;
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null) return;
    setState(() => _isExporting = true);
    try {
      await ReceiptPdfGenerator.generateAndShare(
        context: context,
        result: state.result!,
        orders: state.orders,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingPage,
                0,
                AppTheme.paddingPage,
                AppTheme.spaceLg,
              ),
              child: RepaintBoundary(
                key: _receiptKey,
                child: const _ReceiptContent(),
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
            child: _ReceiptActions(
              isSharing: _isSharing,
              isExporting: _isExporting,
              onShare: _onShare,
              onExportPdf: _onExportPdf,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptActions extends StatelessWidget {
  final bool isSharing;
  final bool isExporting;
  final VoidCallback onShare;
  final VoidCallback onExportPdf;
  const _ReceiptActions({
    required this.isSharing,
    required this.isExporting,
    required this.onShare,
    required this.onExportPdf,
  });

  static const _spinner = SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        if (state.status != CalculatorStatus.calculated) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSharing ? null : onShare,
                icon: isSharing ? _spinner : const Icon(Icons.share_rounded),
                label: Text(isSharing ? 'Bentar ya...' : 'Bagikan'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportPdf,
                icon: isExporting
                    ? _spinner
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(isExporting ? 'Bentar ya...' : 'Ekspor PDF'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        if (state.status != CalculatorStatus.calculated ||
            state.result == null) {
          return const SizedBox.shrink();
        }
        final r = state.result!;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [AppTheme.shadowLg],
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppTheme.accentGradient),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text('Struk PatunganKuy', style: AppTheme.heading3),
              Text(_fmt(r.calculatedAt), style: AppTheme.bodySmall),
              const SizedBox(height: AppTheme.spaceXl),
              _RRow(label: 'Subtotal', value: r.totalBase),
              _RRow(label: 'Total Biaya', value: r.totalFees),
              _RRow(
                label: 'Total Diskon',
                value: r.totalDiscount,
                isDeduct: true,
              ),
              const Divider(height: 24),
              _RRow(label: 'Total Bayar', value: r.grandTotal, bold: true),
              const SizedBox(height: AppTheme.spaceXl),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${r.calculatedBills.length}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Per Orang', style: AppTheme.label),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              ...r.calculatedBills.map((b) => _ResultTile(bill: b)),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _RRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool isDeduct;
  const _RRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.isDeduct = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = bold ? AppTheme.priceLarge : AppTheme.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            '${isDeduct ? "− " : ""}${AppTheme.formatRupiah(value)}',
            style: textStyle.copyWith(color: isDeduct ? AppTheme.error : null),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final CalculatedBill bill;
  const _ResultTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bill.name, style: AppTheme.label),
              Text(
                AppTheme.formatRupiah(bill.finalPayable),
                style: AppTheme.price,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pesanan: ${AppTheme.formatRupiah(bill.originalPrice)}  •  '
            '+Biaya: ${AppTheme.formatRupiah(bill.proportionalFee)}  •  '
            '−Diskon: ${AppTheme.formatRupiah(bill.proportionalDiscount)}',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
