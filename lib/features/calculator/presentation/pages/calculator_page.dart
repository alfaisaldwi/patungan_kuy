import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../injection_container.dart';
import '../../../assignment/presentation/models/assignment_result.dart';
import '../../../assignment/presentation/pages/assignment_page.dart';
import '../../../history/domain/entities/bill_history.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../scanner/presentation/bloc/scanner_bloc.dart';
import '../../domain/entities/calculated_bill.dart';
import '../../domain/entities/person_order.dart';
import '../bloc/calculator_bloc.dart';
import '../utils/receipt_image_generator.dart';
import '../utils/receipt_pdf_generator.dart';

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
  final _receiptKey = GlobalKey();
  bool _isSharing = false;
  bool _isExporting = false;

  Future<void> _onShareReceipt() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ReceiptImageGenerator.captureAndShare(context: context, repaintKey: _receiptKey);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _openHistory() async {
    final calc = context.read<CalculatorBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = await Navigator.of(context).push<BillHistory>(
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
    if (entry != null) {
      calc.add(RestoreFromHistory(entry: entry));
      messenger.showSnackBar(
        SnackBar(content: Text('Bill from ${entry.orders.length} person(s) loaded from history.')),
      );
    }
  }

  Future<void> _onExportPdf() async {
    if (_isExporting) return;
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null) return;
    setState(() => _isExporting = true);
    try {
      await ReceiptPdfGenerator.generateAndShare(context: context, result: state.result!, orders: state.orders);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScannerBloc, ScannerState>(
      listener: _onScannerStateChanged,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('PatunganKuy', style: AppTheme.heading3),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Bill history',
              icon: const Icon(Icons.history),
              onPressed: _openHistory,
            ),
            IconButton(
              tooltip: AppTheme.isDark ? 'Light mode' : 'Dark mode',
              icon: Icon(AppTheme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: ThemeController.toggle,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage, vertical: AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ScanBanner(),
                const SizedBox(height: AppTheme.spaceXl),
                const _OrdersHeader(),
                const SizedBox(height: AppTheme.spaceMd),
                const _OrderList(),
                const SizedBox(height: AppTheme.spaceLg),
                const _AddPersonForm(),
                const SizedBox(height: AppTheme.spaceLg),
                const _FeesDiscountSection(),
                const SizedBox(height: AppTheme.spaceXl),
                const _CalculateButton(),
                const SizedBox(height: AppTheme.spaceMd),
                const _ErrorDisplay(),
                const SizedBox(height: AppTheme.spaceLg),
                _ReceiptActions(
                  isSharing: _isSharing,
                  isExporting: _isExporting,
                  onShare: _onShareReceipt,
                  onExportPdf: _onExportPdf,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                RepaintBoundary(key: _receiptKey, child: const _ReceiptContent()),
                const SizedBox(height: AppTheme.space2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScannerStateChanged(BuildContext context, ScannerState state) {
    if (state.status == ScannerStatus.success && state.parsedReceipt != null) {
      Navigator.of(context)
          .push<AssignmentResult>(MaterialPageRoute(builder: (_) => AssignmentPage(receipt: state.parsedReceipt!)))
          .then((result) {
            if (result != null && mounted) _applyAssignmentResult(context, result);
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
    if (result.deliveryFee != null || result.discount != null) {
      calc.add(
        UpdateFeesAndDiscount(
          taxFee: 0,
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
    ).showSnackBar(SnackBar(content: Text('${result.orders.length} person(s) loaded with $total item(s).')));
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner();

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.disabled, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt, color: AppTheme.primary, size: 20),
              ),
              title: Text('Camera', style: AppTheme.body),
              subtitle: Text('Take a photo of your receipt', style: AppTheme.bodySmall),
              onTap: () {
                Navigator.pop(context);
                context.read<ScannerBloc>().add(const PickAndScanImage(fromCamera: true));
              },
            ),
            const Divider(indent: 56),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.accentLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library, color: AppTheme.accent, size: 20),
              ),
              title: Text('Gallery', style: AppTheme.body),
              subtitle: Text('Pick a receipt screenshot', style: AppTheme.bodySmall),
              onTap: () {
                Navigator.pop(context);
                context.read<ScannerBloc>().add(const PickAndScanImage());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = context.watch<ScannerBloc>().state.status == ScannerStatus.loading;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFFFF8E8E)]),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [AppTheme.shadowMd],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InkWell(
          onTap: isScanning ? null : () => _showPicker(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingCard),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
                  child: isScanning
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.document_scanner, color: Colors.white),
                ),
                const SizedBox(width: AppTheme.spaceLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScanning ? 'Scanning...' : 'Scan Receipt',
                        style: AppTheme.heading2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automatically detect items & prices',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white.withAlpha(204)),
                      ),
                    ],
                  ),
                ),
                if (!isScanning)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        return Row(
          children: [
            Text('Orders', style: AppTheme.heading2),
            const SizedBox(width: AppTheme.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: state.orders.isEmpty ? AppTheme.disabled : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${state.orders.length}',
                style: AppTheme.caption.copyWith(
                  color: state.orders.isEmpty ? AppTheme.disabledText : AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        if (state.orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.space2xl),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: AppTheme.disabledText, size: 28),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text('No orders yet', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spaceXs),
                Text('Scan a receipt or add manually', style: AppTheme.bodySmall),
              ],
            ),
          );
        }

        return Column(children: state.orders.map((o) => _OrderTile(order: o)).toList());
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final PersonOrder order;
  const _OrderTile({required this.order});

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditPersonDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFFFF8E8E)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(order.name[0].toUpperCase(), style: AppTheme.label.copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(order.name, style: AppTheme.label)),
                Text(AppTheme.formatRupiah(order.totalPrice), style: AppTheme.price),
                const SizedBox(width: 4),
                _SmallIconButton(icon: Icons.edit_outlined, onTap: () => _openEditDialog(context)),
                _SmallIconButton(
                  icon: Icons.delete_outline,
                  color: AppTheme.error,
                  onTap: () => context.read<CalculatorBloc>().add(RemovePersonOrder(id: order.id)),
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
                      Text(item.name.isNotEmpty ? item.name : '(no name)', style: AppTheme.bodySmall),
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

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: (color ?? AppTheme.textSecondary).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
      ),
    );
  }
}

class _AddPersonForm extends StatefulWidget {
  const _AddPersonForm();
  @override
  State<_AddPersonForm> createState() => _AddPersonFormState();
}

class _AddPersonFormState extends State<_AddPersonForm> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _itemControllers = <({TextEditingController name, TextEditingController price})>[];

  @override
  void initState() {
    super.initState();
    _addItemRow();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _itemControllers) {
      c.name.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  void _addItemRow() =>
      setState(() => _itemControllers.add((name: TextEditingController(), price: TextEditingController())));

  void _removeItemRow(int i) {
    if (_itemControllers.length <= 1) return;
    setState(() {
      _itemControllers[i].name.dispose();
      _itemControllers[i].price.dispose();
      _itemControllers.removeAt(i);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final items = _itemControllers
        .map((c) => OrderItem(name: c.name.text.trim(), price: AppTheme.parseRupiah(c.price.text)))
        .where((i) => i.price > 0)
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one item needs a price.')));
      return;
    }
    context.read<CalculatorBloc>().add(AddPersonOrder(name: _nameController.text.trim(), items: items));
    _nameController.clear();
    for (final c in _itemControllers) {
      c.name.dispose();
      c.price.dispose();
    }
    _itemControllers.clear();
    _addItemRow();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Person', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spaceMd),
            TextFormField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration(label: 'Person Name', hint: 'e.g. Budi'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '${_itemControllers.length}',
                    style: AppTheme.caption.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Items', style: AppTheme.label),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            ...List.generate(_itemControllers.length, (i) {
              final c = _itemControllers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: c.name,
                        decoration: AppTheme.inputDecoration(label: 'Item name', hint: 'Nasi Goreng'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: c.price,
                        decoration: AppTheme.inputDecoration(label: 'Price', hint: '25000'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [AppTheme.rupiahFormatter],
                        validator: i == 0
                            ? (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final p = AppTheme.parseRupiah(v);
                                if (p <= 0) return 'Invalid';
                                return null;
                              }
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: _itemControllers.length > 1
                          ? _SmallIconButton(
                              icon: Icons.remove_rounded,
                              color: AppTheme.error,
                              onTap: () => _removeItemRow(i),
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
            GestureDetector(
              onTap: _addItemRow,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Add Item',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeesDiscountSection extends StatefulWidget {
  const _FeesDiscountSection();
  @override
  State<_FeesDiscountSection> createState() => _FeesDiscountSectionState();
}

class _FeesDiscountSectionState extends State<_FeesDiscountSection> {
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
    _discountCtrl.text = s.discountAmount > 0 ? s.discountAmount.toString() : '';
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
      UpdateFeesAndDiscount(taxFee: tax, deliveryFee: delivery, discountAmount: discount, isDiscountPercentage: _isPct),
    );
  }

  /// Syncs the text fields when fee values change outside this widget
  /// (receipt scan results or a bill restored from history). A no-op while
  /// the user is typing, since then controller and state already match.
  void _syncFromState(CalculatorState s) {
    setState(() {
      _isPct = s.isDiscountPercentage;
      if (AppTheme.parseRupiah(_taxCtrl.text) != s.taxFee) {
        _taxCtrl.text = s.taxFee > 0 ? AppTheme.formatRupiah(s.taxFee) : '';
      }
      if (AppTheme.parseRupiah(_deliveryCtrl.text) != s.deliveryFee) {
        _deliveryCtrl.text = s.deliveryFee > 0 ? AppTheme.formatRupiah(s.deliveryFee) : '';
      }
      if (AppTheme.parseRupiah(_discountCtrl.text) != s.discountAmount) {
        _discountCtrl.text = s.discountAmount > 0
            ? (_isPct ? s.discountAmount.toString() : AppTheme.formatRupiah(s.discountAmount))
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
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.paddingCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fees & Discount', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: _deliveryCtrl,
            decoration: AppTheme.inputDecoration(label: 'Delivery Fee', hint: '0'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppTheme.rupiahFormatter],
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextFormField(
            controller: _taxCtrl,
            decoration: AppTheme.inputDecoration(label: 'Tax', hint: '0'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppTheme.rupiahFormatter],
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextFormField(
            controller: _discountCtrl,
            decoration: AppTheme.inputDecoration(
              label: _isPct ? 'Discount (%)' : 'Discount',
              hint: '0',
              prefixText: _isPct ? '% ' : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _isPct ? null : [AppTheme.rupiahFormatter],
            onChanged: (_) => _emit(),
          ),
          SwitchListTile(
            title: Text('Discount is percentage', style: AppTheme.bodySmall),
            value: _isPct,
            onChanged: (v) {
              setState(() => _isPct = v);
              _emit();
            },
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
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
                : () => context.read<CalculatorBloc>().add(const CalculateBillEvent()),
            icon: const Icon(Icons.calculate_outlined, size: 20),
            label: const Text('Calculate Split', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
        if (state.status != CalculatorStatus.error || state.errorMessage == null) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(state.errorMessage!, style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
              ),
            ],
          ),
        );
      },
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
        if (state.status != CalculatorStatus.calculated) return const SizedBox.shrink();
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSharing ? null : onShare,
                icon: isSharing ? _spinner : const Icon(Icons.share_rounded),
                label: Text(isSharing ? 'Generating...' : 'Share'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportPdf,
                icon: isExporting ? _spinner : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(isExporting ? 'Exporting...' : 'Export PDF'),
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
        if (state.status != CalculatorStatus.calculated || state.result == null) {
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
                  gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFF7EDDD6)]),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text('PatunganKuy Receipt', style: AppTheme.heading3),
              Text(_fmt(DateTime.now()), style: AppTheme.bodySmall),
              const SizedBox(height: AppTheme.spaceXl),
              _RRow(label: 'Total Base', value: r.totalBase),
              _RRow(label: 'Total Fees', value: r.totalFees),
              _RRow(label: 'Total Discount', value: r.totalDiscount, isDeduct: true),
              const Divider(height: 24),
              _RRow(label: 'Grand Total', value: r.grandTotal, bold: true),
              const SizedBox(height: AppTheme.spaceXl),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${r.calculatedBills.length}',
                      style: AppTheme.caption.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Per Person', style: AppTheme.label),
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
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _RRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool isDeduct;
  const _RRow({required this.label, required this.value, this.bold = false, this.isDeduct = false});

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
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bill.name, style: AppTheme.label),
              Text(AppTheme.formatRupiah(bill.finalPayable), style: AppTheme.price),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Base: ${AppTheme.formatRupiah(bill.originalPrice)}  •  '
            '+Fee: ${AppTheme.formatRupiah(bill.proportionalFee)}  •  '
            '−Disc: ${AppTheme.formatRupiah(bill.proportionalDiscount)}',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

class _EditPersonDialog extends StatefulWidget {
  final PersonOrder order;
  const _EditPersonDialog({required this.order});
  @override
  State<_EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends State<_EditPersonDialog> {
  late final _nameCtrl = TextEditingController(text: widget.order.name);
  late final _itemCtrls = widget.order.items
      .map(
        (item) =>
            (name: TextEditingController(text: item.name), price: TextEditingController(text: item.price.toString())),
      )
      .toList();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _itemCtrls) {
      c.name.dispose();
      c.price.dispose();
    }
    super.dispose();
  }

  void _add() => setState(() => _itemCtrls.add((name: TextEditingController(), price: TextEditingController())));

  void _remove(int i) {
    if (_itemCtrls.length <= 1) return;
    setState(() {
      _itemCtrls[i].name.dispose();
      _itemCtrls[i].price.dispose();
      _itemCtrls.removeAt(i);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final items = _itemCtrls
        .map((c) => OrderItem(name: c.name.text.trim(), price: AppTheme.parseRupiah(c.price.text)))
        .where((i) => i.price > 0)
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one valid item required.')));
      return;
    }
    context.read<CalculatorBloc>().add(
      UpdatePersonOrder(id: widget.order.id, name: _nameCtrl.text.trim(), items: items),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Order', style: AppTheme.heading3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: AppTheme.inputDecoration(label: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text('Items', style: AppTheme.label),
                const SizedBox(height: AppTheme.spaceSm),
                ...List.generate(_itemCtrls.length, (i) {
                  final c = _itemCtrls[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: c.name,
                            decoration: AppTheme.inputDecoration(label: 'Item', hint: 'optional'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: c.price,
                            decoration: AppTheme.inputDecoration(label: 'Price'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [AppTheme.rupiahFormatter],
                            validator: i == 0
                                ? (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final p = AppTheme.parseRupiah(v);
                                    if (p <= 0) return 'Invalid';
                                    return null;
                                  }
                                : null,
                          ),
                        ),
                        if (_itemCtrls.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 20),
                            onPressed: () => _remove(i),
                          ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Center(
                      child: Text(
                        '+ Add Item',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
