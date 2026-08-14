import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/bill_history.dart';
import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  final void Function(BillHistory entry)? onLoadToCalculator;
  const HistoryPage({super.key, this.onLoadToCalculator});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (_) => sl<HistoryBloc>()..add(const LoadHistory()),
      child: _HistoryView(onLoadToCalculator: onLoadToCalculator),
    );
  }
}

class _HistoryView extends StatelessWidget {
  final void Function(BillHistory entry)? onLoadToCalculator;
  const _HistoryView({this.onLoadToCalculator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.paddingPage, AppTheme.spaceLg, AppTheme.paddingPage, 0),
                  sliver: SliverToBoxAdapter(child: _HistoryHeader(entryCount: state.entries.length)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space2xl)),
                _buildBody(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.status == HistoryStatus.loading || state.status == HistoryStatus.initial) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (state.status == HistoryStatus.error) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingPage),
            child: Text(
              state.errorMessage ?? 'Gagal memuat riwayat.',
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (state.entries.isEmpty) {
      return const SliverFillRemaining(hasScrollBody: false, child: _EmptyState());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppTheme.paddingPage, 0, AppTheme.paddingPage, AppTheme.space2xl),
      sliver: SliverList.separated(
        itemCount: state.entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMd),
        itemBuilder: (context, index) =>
            _HistoryCard(entry: state.entries[index], onLoadToCalculator: onLoadToCalculator),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int entryCount;
  const _HistoryHeader({required this.entryCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat', style: AppTheme.heading3),
              Text(
                entryCount == 0 ? 'Belum ada tagihan tersimpan' : '$entryCount tagihan tersimpan',
                style: AppTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (entryCount > 0)
          IconButton(
            tooltip: 'Hapus semua',
            onPressed: () => _confirmClearAll(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            color: AppTheme.textSecondary,
          ),
      ],
    );
  }

  void _confirmClearAll(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus semua riwayat?', style: AppTheme.heading3),
        content: Text('Semua tagihan tersimpan akan dihapus permanen.', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              bloc.add(const ClearHistory());
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus Semua', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(Icons.receipt_long_rounded, color: AppTheme.accent, size: 32),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            Text('Belum ada tagihan tersimpan', style: AppTheme.heading3, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Tagihan yang udah dihitung akan otomatis\nkesimpan di sini',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BillHistory entry;
  final void Function(BillHistory entry)? onLoadToCalculator;

  const _HistoryCard({required this.entry, this.onLoadToCalculator});

  @override
  Widget build(BuildContext context) {
    final names = entry.orders.map((o) => o.name).join(', ');
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => context.read<HistoryBloc>().add(DeleteHistoryEntry(id: entry.id)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: () => _showDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(entry.createdAt),
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Text(
                        AppTheme.formatRupiah(entry.result.grandTotal),
                        style: AppTheme.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(names, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          '${entry.orders.length} orang',
                          style: AppTheme.caption.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceXs),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
      builder: (_) => _HistoryDetailSheet(entry: entry, onLoadToCalculator: onLoadToCalculator),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus tagihan ini?', style: AppTheme.heading3),
        content: Text('Tagihan ini akan dihapus permanen.', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static String _formatDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${m[d.month - 1]} ${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  final BillHistory entry;
  final void Function(BillHistory entry)? onLoadToCalculator;

  const _HistoryDetailSheet({required this.entry, this.onLoadToCalculator});

  @override
  Widget build(BuildContext context) {
    final r = entry.result;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppTheme.disabled, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceXl),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _HistoryCard._formatDate(entry.createdAt),
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTheme.formatRupiah(r.grandTotal),
                        style: AppTheme.priceLarge.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.orders.length} orang ikut patungan',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    children: [
                      _row('Subtotal', r.totalBase),
                      const SizedBox(height: AppTheme.spaceSm),
                      _row('Total Biaya', r.totalFees),
                      const SizedBox(height: AppTheme.spaceSm),
                      _row('Total Diskon', r.totalDiscount, isDeduct: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXl),
                Text('Rincian per Orang', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spaceMd),
                ...entry.orders.map((order) {
                  final bill = r.calculatedBills.where((b) => b.personId == order.id).toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border.withAlpha(128)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  order.name.isNotEmpty ? order.name[0].toUpperCase() : '?',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                            Expanded(child: Text(order.name, style: AppTheme.label)),
                            if (bill.isNotEmpty)
                              Text(AppTheme.formatRupiah(bill.first.finalPayable), style: AppTheme.price),
                          ],
                        ),
                        if (order.items.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spaceSm),
                          const Divider(height: 1),
                          const SizedBox(height: AppTheme.spaceSm),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name.isEmpty ? 'Item' : item.name,
                                      style: AppTheme.caption,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(AppTheme.formatRupiah(item.price), style: AppTheme.caption),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.spaceLg),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.paddingPage, 0, AppTheme.paddingPage, AppTheme.spaceXl),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restore, size: 20),
                label: const Text('Muat ke Kalkulator'),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  final callback = onLoadToCalculator;
                  if (callback != null) {
                    callback(entry);
                  } else {
                    navigator.pop(entry);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool isDeduct = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.body),
        Text(
          '${isDeduct ? "- " : ""}${AppTheme.formatRupiah(value)}',
          style: AppTheme.body.copyWith(color: isDeduct ? AppTheme.error : null, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
