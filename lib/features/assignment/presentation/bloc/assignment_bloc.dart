import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../calculator/domain/entities/person_order.dart';
import '../../../scanner/domain/entities/parsed_receipt.dart';
import '../models/assignment_models.dart';

part 'assignment_event.dart';
part 'assignment_state.dart';

class ReceiptAssignmentBloc extends Bloc<AssignmentEvent, AssignmentState> {
  ReceiptAssignmentBloc() : super(const AssignmentState()) {
    on<LoadScannedItems>(_onLoadScannedItems);
    on<AddPerson>(_onAddPerson);
    on<RemovePerson>(_onRemovePerson);
    on<ToggleItemAssignment>(_onToggleItemAssignment);
    on<FinalizeAssignment>(_onFinalizeAssignment);
  }

  void _onLoadScannedItems(LoadScannedItems event, Emitter<AssignmentState> emit) {
    final allItems = <AssignableItem>[];
    var counter = 0;

    for (final order in event.receipt.orders) {
      for (final item in order.items) {
        allItems.add(
          AssignableItem(
            id: 'item_${counter++}',
            name: item.name.isNotEmpty ? item.name : order.name,
            price: item.price,
          ),
        );
      }
    }

    emit(
      state.copyWith(
        items: allItems,
        persons: const [],
        status: AssignmentStatus.editing,
        receiptSubtotal: event.receipt.detectedSubtotal,
        receiptDeliveryFee: event.receipt.detectedDeliveryFee,
        receiptDiscount: event.receipt.detectedDiscount,
        clearError: true,
        clearFinalized: true,
      ),
    );
  }

  void _onAddPerson(AddPerson event, Emitter<AssignmentState> emit) {
    final name = event.name.trim();
    if (name.isEmpty) return;

    if (state.persons.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      emit(state.copyWith(errorMessage: '"$name" already added.'));
      return;
    }

    final newPerson = Person(id: 'person_${state.persons.length}_${DateTime.now().microsecondsSinceEpoch}', name: name);

    emit(state.copyWith(persons: [...state.persons, newPerson], clearError: true, clearFinalized: true));
  }

  void _onRemovePerson(RemovePerson event, Emitter<AssignmentState> emit) {
    final updatedPersons = state.persons.where((p) => p.id != event.personId).toList();

    final updatedItems = state.items.map((item) {
      if (item.isAssignedTo(event.personId)) {
        return item.copyWith(clearAssignment: true);
      }
      return item;
    }).toList();

    emit(state.copyWith(persons: updatedPersons, items: updatedItems, clearFinalized: true, clearError: true));
  }

  void _onToggleItemAssignment(ToggleItemAssignment event, Emitter<AssignmentState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id != event.itemId) return item;

      if (item.isAssignedTo(event.personId)) {

        return item.copyWith(clearAssignment: true);
      } else if (item.isUnassigned) {

        return item.copyWith(assignedPersonId: event.personId);
      } else {

        return item;
      }
    }).toList();

    emit(state.copyWith(items: updatedItems, clearFinalized: true));
  }

  void _onFinalizeAssignment(FinalizeAssignment event, Emitter<AssignmentState> emit) {
    final allItems = List<AssignableItem>.from(state.items);
    if (allItems.isEmpty) {
      emit(state.copyWith(errorMessage: 'No items to finalize.'));
      return;
    }

    final allAssigned = allItems.every((i) => !i.isUnassigned);
    if (!allAssigned) {
      final unassignedCount = allItems.where((i) => i.isUnassigned).length;
      emit(state.copyWith(errorMessage: '$unassignedCount item(s) are still unassigned. Assign all items first.'));
      return;
    }

    final orders = <PersonOrder>[];
    for (final person in state.persons) {
      final personItems = allItems
          .where((i) => i.isAssignedTo(person.id))
          .map((i) => OrderItem(name: i.name, price: i.price))
          .toList();

      if (personItems.isNotEmpty) {
        orders.add(PersonOrder(id: person.id, name: person.name, items: personItems));
      }
    }

    emit(state.copyWith(status: AssignmentStatus.finalized, finalizedOrders: orders, clearError: true));
  }
}
