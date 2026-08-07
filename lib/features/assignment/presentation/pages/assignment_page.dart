import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../scanner/domain/entities/parsed_receipt.dart';
import '../bloc/assignment_bloc.dart';
import '../models/assignment_models.dart';
import '../models/assignment_result.dart';

class AssignmentPage extends StatelessWidget {
  final ParsedReceipt receipt;

  const AssignmentPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReceiptAssignmentBloc>(
      create: (_) {
        final bloc = ReceiptAssignmentBloc();
        bloc.add(LoadScannedItems(receipt: receipt));
        return bloc;
      },
      child: const _AssignmentView(),
    );
  }
}

class _AssignmentView extends StatefulWidget {
  const _AssignmentView();

  @override
  State<_AssignmentView> createState() => _AssignmentViewState();
}

class _AssignmentViewState extends State<_AssignmentView> {
  final _nameController = TextEditingController();

  String? _pendingNewPersonName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPersonAndAssign() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    _pendingNewPersonName = name;
    context.read<ReceiptAssignmentBloc>().add(AddPerson(name: name));
    _nameController.clear();
  }

  void _confirmRemovePerson(
    BuildContext context,
    Person person,
    int assignedCount,
  ) {
    final bloc = context.read<ReceiptAssignmentBloc>();
    if (assignedCount == 0) {
      bloc.add(RemovePerson(personId: person.id));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus ${person.name}?', style: AppTheme.heading3),
        content: Text(
          '$assignedCount item yang dia ikuti akan balik jadi belum kebagi.',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(RemovePerson(personId: person.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _openChecklist(Person person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ReceiptAssignmentBloc>(),
        child: _AssignmentChecklistSheet(person: person),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReceiptAssignmentBloc, AssignmentState>(
      listener: (context, state) {
        if (state.status == AssignmentStatus.finalized &&
            state.finalizedOrders != null) {
          Navigator.of(context).pop(
            AssignmentResult(
              orders: state.finalizedOrders!,
              subtotal: state.receiptSubtotal,
              tax: state.receiptTax,
              deliveryFee: state.receiptDeliveryFee,
              discount: state.receiptDiscount,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
            ),
          );
        }

        if (_pendingNewPersonName != null) {
          final targetName = _pendingNewPersonName!.toLowerCase();
          final match = state.persons
              .where((p) => p.name.toLowerCase() == targetName)
              .firstOrNull;
          if (match != null) {
            _pendingNewPersonName = null;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openChecklist(match);
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Bagi-bagi Item', style: AppTheme.heading3)),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingPage,
                  AppTheme.spaceLg,
                  AppTheme.paddingPage,
                  AppTheme.spaceSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: AppTheme.inputDecoration(
                          label: 'Nama',
                          hint: 'Misal: Adam',
                        ),
                        onFieldSubmitted: (_) => _addPersonAndAssign(),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    ElevatedButton.icon(
                      onPressed: _addPersonAndAssign,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
              ),

              const _ScannedItemsCard(),

              Expanded(
                child: BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
                  builder: (context, state) {
                    if (state.persons.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXl,
                                ),
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: AppTheme.disabledText,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            Text(
                              'Tambah anggota dulu, yuk',
                              style: AppTheme.heading3,
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text(
                              'Biar item hasil scan bisa dibagi ke tiap orang',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingPage,
                        vertical: AppTheme.spaceSm,
                      ),
                      itemCount: state.persons.length,
                      itemBuilder: (_, index) {
                        final person = state.persons[index];
                        final total = state.assignedTotalFor(person.id);
                        final count = state.items
                            .where((i) => i.isAssignedTo(person.id))
                            .length;
                        final totalItems = state.items.length;

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spaceSm,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: AppTheme.border.withAlpha(128),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            child: InkWell(
                              onTap: () => _openChecklist(person),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceMd,
                                  vertical: AppTheme.spaceMd,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: AppTheme.primaryGradient,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          person.name[0].toUpperCase(),
                                          style: AppTheme.label.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            person.name,
                                            style: AppTheme.label,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            count > 0
                                                ? '$count/$totalItems item  •  ${AppTheme.formatRupiah(total)}'
                                                : 'Belum ada item',
                                            style: AppTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.checklist_rounded,
                                        color: AppTheme.accent,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: 'Hapus',
                                      child: Material(
                                        color: AppTheme.errorLight,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          onTap: () => _confirmRemovePerson(
                                            context,
                                            person,
                                            count,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: AppTheme.error,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
                builder: (context, state) {
                  final unassigned = state.items
                      .where((i) => i.isUnassigned)
                      .length;
                  final totalItems = state.items.length;
                  final allDone = unassigned == 0 && totalItems > 0;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.paddingPage,
                      AppTheme.spaceMd,
                      AppTheme.paddingPage,
                      AppTheme.paddingPage,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spaceSm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: allDone
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  allDone
                                      ? 'Semua item udah kebagi!'
                                      : '$unassigned dari $totalItems item belum kebagi',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: allDone
                                        ? AppTheme.success
                                        : AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                state.items.isNotEmpty &&
                                    state.persons.isNotEmpty
                                ? () => context
                                      .read<ReceiptAssignmentBloc>()
                                      .add(const FinalizeAssignment())
                                : null,
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text(
                              'Selesai, Lanjut Hitung',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannedItemsCard extends StatelessWidget {
  const _ScannedItemsCard();

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ReceiptAssignmentBloc>(),
        child: const _ItemsEditorSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();
        final total = state.itemsTotal;
        final subtotal = state.receiptSubtotal;
        final matches = subtotal != null && (total - subtotal).abs() < 1;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingPage,
            0,
            AppTheme.paddingPage,
            AppTheme.spaceSm,
          ),
          child: Container(
            decoration: AppTheme.cardDecoration,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: InkWell(
                onTap: () => _openEditor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.items.length} item kebaca  •  ${AppTheme.formatRupiah(total)}',
                              style: AppTheme.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtotal == null
                                  ? 'Ketuk buat cek & koreksi hasil scan'
                                  : matches
                                  ? 'Cocok sama subtotal struk'
                                  : 'Beda sama subtotal struk (${AppTheme.formatRupiah(subtotal)})',
                              style: AppTheme.bodySmall.copyWith(
                                color: subtotal == null
                                    ? AppTheme.textSecondary
                                    : matches
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.accent,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemsEditorSheet extends StatelessWidget {
  const _ItemsEditorSheet();

  void _openItemDialog(BuildContext context, {AssignableItem? item}) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ReceiptAssignmentBloc>(),
        child: _EditItemDialog(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
        builder: (context, state) {
          final subtotal = state.receiptSubtotal;
          final matches =
              subtotal != null && (state.itemsTotal - subtotal).abs() < 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.disabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingPage,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Koreksi Item', style: AppTheme.heading3),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        'Total ${AppTheme.formatRupiah(state.itemsTotal)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (subtotal != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingPage,
                    AppTheme.spaceSm,
                    AppTheme.paddingPage,
                    0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: matches ? AppTheme.success : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          matches
                              ? 'Udah cocok sama subtotal di struk (${AppTheme.formatRupiah(subtotal)})'
                              : 'Subtotal di struk ${AppTheme.formatRupiah(subtotal)} — cek lagi, ya',
                          style: AppTheme.bodySmall.copyWith(
                            color: matches
                                ? AppTheme.success
                                : AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: AppTheme.spaceXl),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingPage,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (_, index) {
                    final item = state.items[index];
                    final owners = state.persons
                        .where((p) => item.isAssignedTo(p.id))
                        .map((p) => p.name)
                        .join(', ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd,
                        vertical: AppTheme.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.border.withAlpha(128),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name.isNotEmpty
                                      ? item.name
                                      : '(tanpa nama)',
                                  style: AppTheme.body,
                                ),
                                Text(
                                  owners.isEmpty
                                      ? AppTheme.formatRupiah(item.price)
                                      : '${AppTheme.formatRupiah(item.price)}  •  Punya $owners',
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ubah',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: AppTheme.textSecondary,
                            onPressed: () =>
                                _openItemDialog(context, item: item),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: AppTheme.error,
                            onPressed: () => context
                                .read<ReceiptAssignmentBloc>()
                                .add(RemoveScannedItem(itemId: item.id)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingPage,
                  AppTheme.spaceSm,
                  AppTheme.paddingPage,
                  AppTheme.spaceXl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openItemDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Item'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final AssignableItem? item;

  const _EditItemDialog({this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
  late final _priceCtrl = TextEditingController(
    text: widget.item != null ? AppTheme.formatRupiah(widget.item!.price) : '',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<ReceiptAssignmentBloc>();
    final name = _nameCtrl.text.trim();
    final price = AppTheme.parseRupiah(_priceCtrl.text);
    if (widget.item == null) {
      bloc.add(AddScannedItem(name: name, price: price));
    } else {
      bloc.add(
        UpdateScannedItem(itemId: widget.item!.id, name: name, price: price),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Tambah Item' : 'Ubah Item',
        style: AppTheme.heading3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: AppTheme.inputDecoration(
                label: 'Nama item',
                hint: 'Nasi Goreng',
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextFormField(
              controller: _priceCtrl,
              decoration: AppTheme.inputDecoration(
                label: 'Harga',
                hint: '25000',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AppTheme.rupiahFormatter],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (AppTheme.parseRupiah(v) <= 0) return 'Nggak valid';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

class _AssignmentChecklistSheet extends StatelessWidget {
  final Person person;

  const _AssignmentChecklistSheet({required this.person});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) =>
          BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
            builder: (context, state) {
              final total = state.assignedTotalFor(person.id);
              final count = state.items
                  .where((i) => i.isAssignedTo(person.id))
                  .length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.disabled,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingPage,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              person.name[0].toUpperCase(),
                              style: AppTheme.label.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Item ${person.name}',
                            style: AppTheme.heading3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            '$count item  •  ${AppTheme.formatRupiah(total)}',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: AppTheme.spaceXl),

                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: state.items.length,
                      itemBuilder: (_, index) {
                        final item = state.items[index];
                        final isMine = item.isAssignedTo(person.id);
                        final otherNames = state.persons
                            .where(
                              (p) =>
                                  p.id != person.id && item.isAssignedTo(p.id),
                            )
                            .map((p) => p.name)
                            .toList();

                        final takenByOthers = !isMine && otherNames.isNotEmpty;

                        final String subtitle;
                        if (isMine && item.isShared) {
                          subtitle =
                              '${AppTheme.formatRupiah(item.sharePrice)}/orang  •  bareng ${otherNames.join(', ')}';
                        } else if (takenByOthers) {
                          subtitle =
                              '${AppTheme.formatRupiah(item.price)}  •  Punya ${otherNames.join(', ')} — ketuk buat ikut patungan';
                        } else {
                          subtitle = AppTheme.formatRupiah(item.price);
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppTheme.primaryLight
                                : takenByOthers
                                ? AppTheme.warningLight
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: isMine
                                  ? AppTheme.primary.withAlpha(77)
                                  : takenByOthers
                                  ? AppTheme.warning.withAlpha(77)
                                  : AppTheme.border.withAlpha(128),
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: CheckboxListTile(
                              value: isMine,
                              onChanged: (_) =>
                                  context.read<ReceiptAssignmentBloc>().add(
                                    ToggleItemAssignment(
                                      itemId: item.id,
                                      personId: person.id,
                                    ),
                                  ),
                              title: Text(item.name, style: AppTheme.body),
                              subtitle: Text(
                                subtitle,
                                style: AppTheme.bodySmall,
                              ),
                              activeColor: AppTheme.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
