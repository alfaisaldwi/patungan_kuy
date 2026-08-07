import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/calculator_bloc.dart';

class FeesDiscountSection extends StatefulWidget {
  const FeesDiscountSection({super.key});

  @override
  State<FeesDiscountSection> createState() => _FeesDiscountSectionState();
}

class _FeesDiscountSectionState extends State<FeesDiscountSection> {
  final _taxCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _isPct = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<CalculatorBloc>().state;
    _taxCtrl.text = s.taxFee > 0 ? s.taxFee.toString() : '';
    _deliveryCtrl.text = s.deliveryFee > 0 ? s.deliveryFee.toString() : '';
    _discountCtrl.text = s.discountAmount > 0
        ? s.discountAmount.toString()
        : '';
    _isPct = s.isDiscountPercentage;
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    _deliveryCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final tax = AppTheme.parseRupiah(_taxCtrl.text);
    final delivery = AppTheme.parseRupiah(_deliveryCtrl.text);
    final discount = AppTheme.parseRupiah(_discountCtrl.text);
    context.read<CalculatorBloc>().add(
      UpdateFeesAndDiscount(
        taxFee: tax,
        deliveryFee: delivery,
        discountAmount: discount,
        isDiscountPercentage: _isPct,
      ),
    );
  }

  void _setPct(bool value) {
    if (_isPct == value) return;
    setState(() {
      _isPct = value;
      _discountCtrl.clear();
    });
    _emit();
  }

  void _syncFromState(CalculatorState s) {
    setState(() {
      _isPct = s.isDiscountPercentage;
      if (AppTheme.parseRupiah(_taxCtrl.text) != s.taxFee) {
        _taxCtrl.text = s.taxFee > 0 ? AppTheme.formatRupiah(s.taxFee) : '';
      }
      if (AppTheme.parseRupiah(_deliveryCtrl.text) != s.deliveryFee) {
        _deliveryCtrl.text = s.deliveryFee > 0
            ? AppTheme.formatRupiah(s.deliveryFee)
            : '';
      }
      if (AppTheme.parseRupiah(_discountCtrl.text) != s.discountAmount) {
        _discountCtrl.text = s.discountAmount > 0
            ? (_isPct
                  ? s.discountAmount.toString()
                  : AppTheme.formatRupiah(s.discountAmount))
            : '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalculatorBloc, CalculatorState>(
      listenWhen: (prev, curr) =>
          prev.taxFee != curr.taxFee ||
          prev.deliveryFee != curr.deliveryFee ||
          prev.discountAmount != curr.discountAmount ||
          prev.isDiscountPercentage != curr.isDiscountPercentage,
      listener: (context, state) => _syncFromState(state),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final feesTotal = state.taxFee + state.deliveryFee;
        final hasFees = feesTotal > 0 || state.discountAmount > 0;
        final baseTotal = state.orders.fold<double>(
          0,
          (s, o) => s + o.totalPrice,
        );
        final discountValue = state.isDiscountPercentage
            ? (state.discountAmount / 100) * baseTotal
            : state.discountAmount;

        return Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(AppTheme.paddingCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _deliveryCtrl,
                decoration: AppTheme.inputDecoration(
                  label: 'Ongkir',
                  hint: '0',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppTheme.rupiahFormatter],
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              TextFormField(
                controller: _taxCtrl,
                decoration: AppTheme.inputDecoration(label: 'Pajak', hint: '0'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppTheme.rupiahFormatter],
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountCtrl,
                      decoration: AppTheme.inputDecoration(
                        label: 'Diskon',
                        hint: '0',
                        suffixText: _isPct ? '%' : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: _isPct
                          ? null
                          : [AppTheme.rupiahFormatter],
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  _DiscountModeToggle(isPct: _isPct, onChanged: _setPct),
                ],
              ),
              if (hasFees && baseTotal > 0) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          'Subtotal ${AppTheme.formatRupiah(baseTotal)}',
                          if (feesTotal > 0)
                            '+ Biaya ${AppTheme.formatRupiah(feesTotal)}',
                          if (discountValue > 0)
                            '− Diskon ${AppTheme.formatRupiah(discountValue)}',
                          '= ${AppTheme.formatRupiah(baseTotal + feesTotal - discountValue)}',
                        ].join(' '),
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DiscountModeToggle extends StatelessWidget {
  final bool isPct;
  final ValueChanged<bool> onChanged;
  const _DiscountModeToggle({required this.isPct, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            label: 'Rp',
            selected: !isPct,
            onTap: () => onChanged(false),
          ),
          _segment(label: '%', selected: isPct, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
