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

  void _openChecklist(Person person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl))),
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
        if (state.status == AssignmentStatus.finalized && state.finalizedOrders != null) {
          Navigator.of(context).pop(
            AssignmentResult(
              orders: state.finalizedOrders!,
              subtotal: state.receiptSubtotal,
              deliveryFee: state.receiptDeliveryFee,
              discount: state.receiptDiscount,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.error));
        }

        if (_pendingNewPersonName != null) {
          final targetName = _pendingNewPersonName!.toLowerCase();
          final match = state.persons.where((p) => p.name.toLowerCase() == targetName).firstOrNull;
          if (match != null) {
            _pendingNewPersonName = null;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openChecklist(match);
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Item Assignment', style: AppTheme.heading3)),
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
                        decoration: AppTheme.inputDecoration(label: 'Person Name', hint: 'e.g. Adam'),
                        onFieldSubmitted: (_) => _addPersonAndAssign(),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    ElevatedButton.icon(
                      onPressed: _addPersonAndAssign,
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),

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
                                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              ),
                              child: Icon(Icons.people_outline, color: AppTheme.disabledText, size: 32),
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            Text('Add group members', style: AppTheme.heading3),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text('Assign scanned items to each person', style: AppTheme.bodySmall),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage, vertical: AppTheme.spaceSm),
                      itemCount: state.persons.length,
                      itemBuilder: (_, index) {
                        final person = state.persons[index];
                        final total = state.assignedTotalFor(person.id);
                        final count = state.items.where((i) => i.isAssignedTo(person.id)).length;
                        final totalItems = state.items.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.border.withAlpha(128)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            child: InkWell(
                              onTap: () => _openChecklist(person),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          person.name[0].toUpperCase(),
                                          style: AppTheme.label.copyWith(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(person.name, style: AppTheme.label),
                                          const SizedBox(height: 2),
                                          Text(
                                            count > 0
                                                ? '$count/$totalItems items  •  ${AppTheme.formatRupiah(total)}'
                                                : 'No items assigned',
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
                                      child: const Icon(Icons.checklist_rounded, color: AppTheme.accent, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () =>
                                          context.read<ReceiptAssignmentBloc>().add(RemovePerson(personId: person.id)),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 18),
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
                  final unassigned = state.items.where((i) => i.isUnassigned).length;
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
                            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: allDone ? AppTheme.success : AppTheme.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  allDone ? 'All items assigned!' : '$unassigned of $totalItems unassigned',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: allDone ? AppTheme.success : AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: state.items.isNotEmpty && state.persons.isNotEmpty
                                ? () => context.read<ReceiptAssignmentBloc>().add(const FinalizeAssignment())
                                : null,
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text(
                              'Finalize & Send to Calculator',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
      builder: (_, scrollController) => BlocBuilder<ReceiptAssignmentBloc, AssignmentState>(
        builder: (context, state) {
          final total = state.assignedTotalFor(person.id);
          final count = state.items.where((i) => i.isAssignedTo(person.id)).length;

          return Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.disabled, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingPage),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(person.name[0].toUpperCase(), style: AppTheme.label.copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text("${person.name}'s Items", style: AppTheme.heading3)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '$count items  •  ${AppTheme.formatRupiah(total)}',
                        style: AppTheme.caption.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600),
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
                    final isOthers = item.isAssignedToOther(person.id);
                    final otherPerson = isOthers
                        ? state.persons.where((p) => p.id == item.assignedPersonId).map((p) => p.name).firstOrNull
                        : null;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isMine
                            ? AppTheme.primaryLight
                            : isOthers
                            ? AppTheme.background
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isMine
                              ? AppTheme.primary.withAlpha(77)
                              : isOthers
                              ? AppTheme.border
                              : AppTheme.border.withAlpha(128),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isMine,
                        onChanged: isOthers
                            ? null
                            : (_) => context.read<ReceiptAssignmentBloc>().add(
                                ToggleItemAssignment(itemId: item.id, personId: person.id),
                              ),
                        title: Text(
                          item.name,
                          style: AppTheme.body.copyWith(
                            color: isOthers ? AppTheme.disabledText : AppTheme.textPrimary,
                            decoration: isOthers ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: isOthers
                            ? Text('Assigned to $otherPerson', style: AppTheme.bodySmall)
                            : Text(AppTheme.formatRupiah(item.price), style: AppTheme.bodySmall),
                        activeColor: AppTheme.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
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
