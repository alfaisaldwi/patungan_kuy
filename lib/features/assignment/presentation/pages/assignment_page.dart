import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/onboarding/showcase_tour.dart';
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

const _avatarColors = <Color>[
  Color(0xFF6366F1),
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
];

Color _colorForPerson(AssignmentState state, String personId) {
  final index = state.persons.indexWhere((p) => p.id == personId);
  return _avatarColors[(index < 0 ? 0 : index) % _avatarColors.length];
}

class _PersonAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _PersonAvatar({
    required this.name,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void _confirmRemovePerson(
  BuildContext context,
  Person person,
  int assignedCount, {
  VoidCallback? onRemoved,
}) {
  final bloc = context.read<ReceiptAssignmentBloc>();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Hapus ${person.name}?', style: AppTheme.heading3),
      content: Text(
        assignedCount == 0
            ? '${person.name} akan dihapus dari daftar.'
            : '$assignedCount item yang dia ikuti akan balik jadi belum kebagi.',
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
            onRemoved?.call();
          },
          child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    ),
  );
}

class _AssignmentView extends StatefulWidget {
  const _AssignmentView();

  @override
  State<_AssignmentView> createState() => _AssignmentViewState();
}

class _AssignmentViewState extends State<_AssignmentView> {
  final _nameController = TextEditingController();

  String? _pendingNewPersonName;

  late final ShowcaseView _tour = ShowcaseTour.registerAssignment();

  @override
  void initState() {
    super.initState();
    _tour;
    ShowcaseTour.startAssignmentIfFirstTime(canStart: () => mounted);
  }

  @override
  void dispose() {
    _tour.unregister();
    _nameController.dispose();
    super.dispose();
  }

  void _addPersonAndAssign() {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    _pendingNewPersonName = name;
    context.read<ReceiptAssignmentBloc>().add(AddPerson(name: name));
    _nameController.clear();
  }

  void _openChecklist(Person person) {
    FocusManager.instance.primaryFocus?.unfocus();
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

  void _openItemPicker(AssignableItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    final bloc = context.read<ReceiptAssignmentBloc>();
    if (bloc.state.persons.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tambah orang dulu, baru item bisa dibagi.'),
          ),
        );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _ItemPickerSheet(itemId: item.id),
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
                  AppTheme.spaceMd,
                  AppTheme.paddingPage,
                  AppTheme.spaceSm,
                ),
                child: TourTarget(
                  tourKey: ShowcaseTour.assignNameKey,
                  scope: ShowcaseTour.assignmentScope,
                  title: 'Tambah orang',
                  description:
                      'Ketik nama temen yang ikut patungan, lalu ketuk Tambah.',
                  radius: AppTheme.radiusMd,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: AppTheme.body,
                          textInputAction: TextInputAction.done,
                          decoration: AppTheme.inputDecoration(
                            label: 'Nama orang',
                            hint: 'Misal: Adam',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: 20,
                              color: AppTheme.textHint,
                            ),
                          ),
                          onFieldSubmitted: (_) => _addPersonAndAssign(),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _addPersonAndAssign,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tambah'),
                          style: AppTheme.primaryButton.copyWith(
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const _PersonChipsRow(),

              const _ScannedItemsCard(),

              Expanded(child: _ItemsList(onItemTap: _openItemPicker)),

              const _BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonChipsRow extends StatelessWidget {
  const _PersonChipsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
      builder: (context, state) {
        if (state.persons.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
          child: SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingPage,
              ),
              itemCount: state.persons.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final person = state.persons[index];
                final color = _colorForPerson(state, person.id);
                final total = state.assignedTotalFor(person.id);
                return Material(
                  color: AppTheme.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: AppTheme.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => BlocProvider.value(
                          value: context.read<ReceiptAssignmentBloc>(),
                          child: _AssignmentChecklistSheet(person: person),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PersonAvatar(
                            name: person.name,
                            color: color,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: AppTheme.label.copyWith(fontSize: 13),
                              ),
                              Text(
                                total > 0
                                    ? AppTheme.formatRupiah(total)
                                    : 'Belum ada item',
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ItemsList extends StatelessWidget {
  final void Function(AssignableItem item) onItemTap;

  const _ItemsList({required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceXl),
              child: Text(
                'Belum ada item. Ketuk "Koreksi" untuk menambah item.',
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingPage,
            0,
            AppTheme.paddingPage,
            AppTheme.spaceSm,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.persons.isEmpty
                          ? 'Tambah orang dulu, lalu ketuk item untuk membaginya.'
                          : 'Ketuk item untuk pilih siapa yang ikut. Boleh lebih dari satu orang.',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < state.items.length; i++)
              i == 0
                  ? TourTarget(
                      tourKey: ShowcaseTour.assignItemKey,
                      scope: ShowcaseTour.assignmentScope,
                      title: 'Bagi item',
                      description:
                          'Ketuk item, lalu pilih siapa yang ikut. Boleh lebih dari satu orang, harganya dibagi rata.',
                      child: _ItemTile(
                        item: state.items[i],
                        state: state,
                        onTap: () => onItemTap(state.items[i]),
                      ),
                    )
                  : _ItemTile(
                      item: state.items[i],
                      state: state,
                      onTap: () => onItemTap(state.items[i]),
                    ),
          ],
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AssignableItem item;
  final AssignmentState state;
  final VoidCallback onTap;

  const _ItemTile({
    required this.item,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owners = state.persons
        .where((p) => item.isAssignedTo(p.id))
        .toList(growable: false);
    final unassigned = owners.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: unassigned ? AppTheme.warningLight : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: unassigned
              ? AppTheme.warning.withAlpha(110)
              : AppTheme.border.withAlpha(160),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isNotEmpty ? item.name : '(tanpa nama)',
                        style: AppTheme.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.isShared
                            ? '${AppTheme.formatRupiah(item.price)}  •  ${AppTheme.formatRupiah(item.sharePrice)}/orang'
                            : AppTheme.formatRupiah(item.price),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                if (unassigned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withAlpha(40),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_add_alt_1,
                          size: 14,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pilih orang',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _OwnerAvatars(owners: owners, state: state),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerAvatars extends StatelessWidget {
  final List<Person> owners;
  final AssignmentState state;

  const _OwnerAvatars({required this.owners, required this.state});

  static const _maxShown = 3;
  static const _size = 28.0;
  static const _overlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final shown = owners.take(_maxShown).toList();
    final extra = owners.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);

    return Semantics(
      label: 'Dibagi ke ${owners.map((p) => p.name).join(', ')}',
      child: SizedBox(
        width: _size + (count - 1) * _overlap,
        height: _size,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: i * _overlap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2),
                  ),
                  child: _PersonAvatar(
                    name: shown[i].name,
                    color: _colorForPerson(state, shown[i].id),
                    size: _size,
                  ),
                ),
              ),
            if (extra > 0)
              Positioned(
                left: shown.length * _overlap,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
      builder: (context, state) {
        final unassigned = state.items.where((i) => i.isUnassigned).length;
        final totalItems = state.items.length;
        final allDone = unassigned == 0 && totalItems > 0;
        final canFinish = allDone && state.persons.isNotEmpty;

        final String? hint;
        if (totalItems == 0) {
          hint = null;
        } else if (state.persons.isEmpty) {
          hint = 'Tambah minimal satu orang dulu';
        } else if (!allDone) {
          hint = '$unassigned dari $totalItems item belum kebagi';
        } else {
          hint = 'Semua item udah kebagi!';
        }

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
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: canFinish
                              ? AppTheme.success
                              : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hint,
                          style: AppTheme.bodySmall.copyWith(
                            color: canFinish
                                ? AppTheme.success
                                : AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TourTarget(
                tourKey: ShowcaseTour.assignFinishKey,
                scope: ShowcaseTour.assignmentScope,
                title: 'Lanjut hitung',
                description:
                    'Tombol aktif kalau semua item sudah kebagi. Setelah itu tinggal hitung patungannya.',
                radius: AppTheme.radiusFull,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canFinish
                        ? () => context.read<ReceiptAssignmentBloc>().add(
                            const FinalizeAssignment(),
                          )
                        : null,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Selesai, Lanjut Hitung',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannedItemsCard extends StatelessWidget {
  const _ScannedItemsCard();

  void _openEditor(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
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
        final total = state.itemsTotal;
        final subtotal = state.receiptSubtotal;
        final matches = subtotal != null && (total - subtotal).abs() < 1;
        final diff = subtotal == null ? 0.0 : (total - subtotal).abs();

        final statusColor = subtotal == null
            ? AppTheme.textSecondary
            : matches
            ? AppTheme.success
            : AppTheme.warning;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.paddingPage,
            0,
            AppTheme.paddingPage,
            AppTheme.spaceSm,
          ),
          child: TourTarget(
            tourKey: ShowcaseTour.assignEditKey,
            scope: ShowcaseTour.assignmentScope,
            title: 'Cek hasil scan',
            description:
                'Kalau ada nama atau harga yang salah baca, ketuk Koreksi untuk memperbaikinya.',
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
                                '${state.items.length} item dari struk  •  ${AppTheme.formatRupiah(total)}',
                                style: AppTheme.label,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtotal == null
                                    ? 'Ada yang salah baca? Ketuk "Koreksi".'
                                    : matches
                                    ? 'Cocok sama subtotal struk'
                                    : 'Selisih ${AppTheme.formatRupiah(diff)} dari subtotal struk (${AppTheme.formatRupiah(subtotal)}). Cek nama & harga item, ya.',
                                style: AppTheme.bodySmall.copyWith(
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.accent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Koreksi',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _ItemPickerSheet extends StatelessWidget {
  final String itemId;

  const _ItemPickerSheet({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
      builder: (context, state) {
        final item = state.items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) return const SizedBox.shrink();

        final count = item.assignedPersonIds.length;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.isNotEmpty ? item.name : '(tanpa nama)',
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Siapa yang ikut? Pilih satu orang atau lebih.',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppTheme.formatRupiah(item.price),
                      style: AppTheme.price,
                    ),
                  ],
                ),
              ),
              const Divider(height: AppTheme.spaceXl),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final person in state.persons)
                      CheckboxListTile(
                        value: item.isAssignedTo(person.id),
                        onChanged: (_) =>
                            context.read<ReceiptAssignmentBloc>().add(
                              ToggleItemAssignment(
                                itemId: item.id,
                                personId: person.id,
                              ),
                            ),
                        activeColor: AppTheme.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: _PersonAvatar(
                          name: person.name,
                          color: _colorForPerson(state, person.id),
                        ),
                        title: Text(person.name, style: AppTheme.body),
                        subtitle: item.isAssignedTo(person.id)
                            ? Text(
                                '${AppTheme.formatRupiah(item.sharePrice)}${count > 1 ? ' (dibagi rata)' : ''}',
                                style: AppTheme.bodySmall,
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingPage,
                  AppTheme.spaceSm,
                  AppTheme.paddingPage,
                  AppTheme.spaceLg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Selesai'),
                  ),
                ),
              ),
            ],
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
                                      : '${AppTheme.formatRupiah(item.price)}  •  Dipilih $owners',
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

class _AssignmentChecklistSheet extends StatefulWidget {
  final Person person;

  const _AssignmentChecklistSheet({required this.person});

  @override
  State<_AssignmentChecklistSheet> createState() =>
      _AssignmentChecklistSheetState();
}

class _AssignmentChecklistSheetState extends State<_AssignmentChecklistSheet> {
  Person get person => widget.person;

  late final List<String> _order;

  @override
  void initState() {
    super.initState();
    final items = context.read<ReceiptAssignmentBloc>().state.items;
    _order = [
      ...items.where((i) => i.isUnassigned).map((i) => i.id),
      ...items.where((i) => !i.isUnassigned).map((i) => i.id),
    ];
  }

  List<AssignableItem> _orderedItems(List<AssignableItem> items) {
    final byId = {for (final i in items) i.id: i};
    return [
      for (final id in _order)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

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
              final items = _orderedItems(state.items);

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
                        _PersonAvatar(
                          name: person.name,
                          color: _colorForPerson(state, person.id),
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Item ${person.name}',
                            style: AppTheme.heading3,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus ${person.name}',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          color: AppTheme.textHint,
                          onPressed: () => _confirmRemovePerson(
                            context,
                            person,
                            count,
                            onRemoved: () => Navigator.pop(context),
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
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        final isMine = item.isAssignedTo(person.id);
                        final owners = state.persons
                            .where((p) => item.isAssignedTo(p.id))
                            .toList();
                        final otherNames = owners
                            .where((p) => p.id != person.id)
                            .map((p) => p.name)
                            .toList();

                        final takenByOthers = !isMine && otherNames.isNotEmpty;

                        final String subtitle;
                        if (isMine && item.isShared) {
                          subtitle =
                              '${AppTheme.formatRupiah(item.sharePrice)}/orang  •  bareng ${otherNames.join(', ')}';
                        } else if (takenByOthers) {
                          subtitle =
                              '${AppTheme.formatRupiah(item.price)}  •  Centang untuk ikut bagi rata';
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
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: isMine
                                  ? AppTheme.primary.withAlpha(77)
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
                              secondary: owners.isEmpty
                                  ? null
                                  : _OwnerAvatars(owners: owners, state: state),
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
