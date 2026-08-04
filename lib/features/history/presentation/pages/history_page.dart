import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/bill_history.dart';
import '../bloc/history_bloc.dart';

/// Shows saved bills, newest first. Pops with a [BillHistory] when the user
/// chooses to load an entry back into the calculator.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (_) => sl<HistoryBloc>()..add(const LoadHistory()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill History', style: AppTheme.heading3),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state.entries.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear all',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state.status == HistoryStatus.loading || state.status == HistoryStatus.initial) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (state.status == HistoryStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingPage),
                  child: Text(state.errorMessage ?? 'Failed to load history.', style: AppTheme.body),
                ),
              );
            }
            if (state.entries.isEmpty) {
              return const _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage, vertical: AppTheme.spaceLg),
              itemCount: state.entries.length,
              itemBuilder: (context, index) => _HistoryCard(entry: state.entries[index]),
            );
          },
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear all history?', style: AppTheme.heading3),
        content: Text('All saved bills will be permanently removed.', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              bloc.add(const ClearHistory());
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear All', style: TextStyle(color: AppTheme.error)),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            child: Icon(Icons.history, color: AppTheme.disabledText, size: 32),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text('No saved bills yet', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spaceXs),
          Text('Calculated bills are saved here automatically', style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BillHistory entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final names = entry.orders.map((o) => o.name).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      decoration: AppTheme.cardDecoration,
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
                    Expanded(child: Text(_formatDate(entry.createdAt), style: AppTheme.bodySmall)),
                    Text(AppTheme.formatRupiah(entry.result.grandTotal), style: AppTheme.price),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${entry.orders.length} ${entry.orders.length == 1 ? 'person' : 'people'}',
                        style: AppTheme.caption.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Text(names, style: AppTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
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
      builder: (_) => _HistoryDetailSheet(entry: entry),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete this bill?', style: AppTheme.heading3),
        content: Text('This entry will be permanently removed.', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              bloc.add(DeleteHistoryEntry(id: entry.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  final BillHistory entry;

  const _HistoryDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final r = entry.result;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
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
                Text(_HistoryCard._formatDate(entry.createdAt), style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spaceMd),
                _row('Total Base', r.totalBase),
                _row('Total Fees', r.totalFees),
                _row('Total Discount', r.totalDiscount, isDeduct: true),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total', style: AppTheme.priceLarge),
                    Text(AppTheme.formatRupiah(r.grandTotal), style: AppTheme.priceLarge),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLg),
                ...entry.orders.map((order) {
                  final bill = r.calculatedBills.where((b) => b.personId == order.id).toList();
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
                            Text(order.name, style: AppTheme.label),
                            if (bill.isNotEmpty)
                              Text(AppTheme.formatRupiah(bill.first.finalPayable), style: AppTheme.price),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
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
                label: const Text('Load to Calculator'),
                onPressed: () {
                  // Close the sheet, then pop HistoryPage returning the entry.
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.pop(entry);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool isDeduct = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body),
          Text(
            '${isDeduct ? "- " : ""}${AppTheme.formatRupiah(value)}',
            style: AppTheme.body.copyWith(color: isDeduct ? AppTheme.error : null),
          ),
        ],
      ),
    );
  }
}
