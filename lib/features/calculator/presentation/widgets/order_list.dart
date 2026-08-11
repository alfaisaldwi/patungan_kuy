import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../scanner/presentation/bloc/scanner_bloc.dart';
import '../../domain/entities/person_order.dart';
import '../bloc/calculator_bloc.dart';
import 'edit_person_dialog.dart';
import 'promo_carousel.dart';
import 'scan_picker.dart';
import 'small_icon_button.dart';

class OrdersCountBadge extends StatelessWidget {
  const OrdersCountBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: state.orders.isEmpty ? AppTheme.divider : AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '${state.orders.length} orang',
              key: ValueKey(state.orders.length),
              style: AppTheme.caption.copyWith(
                color: state.orders.isEmpty ? AppTheme.disabledText : AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderList extends StatelessWidget {
  final VoidCallback onAddManually;
  const OrderList({super.key, required this.onAddManually});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final Widget child;
        if (state.orders.isEmpty) {
          child = _EmptyOrders(onAddManually: onAddManually);
        } else {
          final subtotal = state.orders.fold<double>(0, (s, o) => s + o.totalPrice);
          child = Column(
            children: [
              Row(
                children: [
                  Text('Subtotal sementara', style: AppTheme.bodySmall),
                  const Spacer(),
                  Text(AppTheme.formatRupiah(subtotal), style: AppTheme.label),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              ...state.orders.map((o) => _OrderTile(key: ValueKey(o.id), order: o)),
              const SizedBox(height: AppTheme.spaceXs),
              _QuickAddRow(onAddManually: onAddManually),
            ],
          );
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback onAddManually;
  const _EmptyOrders({required this.onAddManually});

  @override
  Widget build(BuildContext context) {
    final isScanning = context.watch<ScannerBloc>().state.status == ScannerStatus.loading;

    return Column(
      children: [
        const PromoCarousel(),
        // Text('Pilih salah satu cara di bawah buat mulai', style: AppTheme.bodySmall),
        const SizedBox(height: AppTheme.spaceLg),
        _EmptyStateChoiceCard(
          icon: Icons.document_scanner_rounded,
          iconBg: AppTheme.primaryLight,
          iconColor: AppTheme.primary,
          title: isScanning ? 'Lagi scan...' : 'Scan Struk',
          badge: 'OTOMATIS',
          description:
              'Foto atau pilih gambar struk. Item & harga kebaca '
              'otomatis, tinggal dibagi ke temen.',
          loading: isScanning,
          onTap: isScanning ? null : () => showScanPicker(context),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        _EmptyStateChoiceCard(
          icon: Icons.edit_note_rounded,
          iconBg: AppTheme.accentLight,
          iconColor: AppTheme.accent,
          title: 'Tulis Manual',
          description:
              'Ketik sendiri pesanan tiap orang. '
              'Cocok buat tagihan yang simpel.',
          onTap: onAddManually,
        ),
        const SizedBox(height: AppTheme.spaceLg),
      ],
    );
  }
}

class _EmptyStateChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? badge;
  final String description;
  final bool loading;
  final VoidCallback? onTap;

  const _EmptyStateChoiceCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.badge,
    required this.description,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingCard),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                  child: loading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          ),
                        )
                      : Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spaceLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: AppTheme.label.copyWith(fontSize: 16)),
                          if (badge != null) ...[
                            const SizedBox(width: AppTheme.spaceSm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(description, style: AppTheme.bodySmall.copyWith(height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  final VoidCallback onAddManually;
  const _QuickAddRow({required this.onAddManually});

  @override
  Widget build(BuildContext context) {
    final isScanning = context.watch<ScannerBloc>().state.status == ScannerStatus.loading;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isScanning ? null : () => showScanPicker(context),
            icon: isScanning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                : const Icon(Icons.document_scanner_rounded, size: 16),
            label: Text(isScanning ? 'Lagi scan...' : 'Scan Lagi'),
          ),
        ),
        Expanded(
          child: Visibility(
            visible: false,
            child: OutlinedButton.icon(
              onPressed: onAddManually,
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('Tambah Orang'),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final PersonOrder order;
  const _OrderTile({super.key, required this.order});

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CalculatorBloc>(),
        child: EditPersonDialog(order: order),
      ),
    );
  }

  void _removeWithUndo(BuildContext context) {
    final calc = context.read<CalculatorBloc>();
    calc.add(RemovePersonOrder(id: order.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Pesanan ${order.name} dihapus.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => calc.add(AddPersonOrder(name: order.name, items: order.items)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: _buildTile(context),
    );
  }

  Widget _buildTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(order.name[0].toUpperCase(), style: AppTheme.label.copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(order.name, style: AppTheme.label)),
                Text(AppTheme.formatRupiah(order.totalPrice), style: AppTheme.price),
                const SizedBox(width: 6),
                SmallIconButton(icon: Icons.edit_outlined, tooltip: 'Ubah', onTap: () => _openEditDialog(context)),
                const SizedBox(width: 4),
                SmallIconButton(
                  icon: Icons.delete_outline,
                  color: AppTheme.error,
                  tooltip: 'Hapus',
                  onTap: () => _removeWithUndo(context),
                ),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spaceSm),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name.isNotEmpty ? item.name : '(tanpa nama)', style: AppTheme.bodySmall),
                      Text(AppTheme.formatRupiah(item.price), style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
