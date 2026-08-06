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
    on<UpdateScannedItem>(_onUpdateScannedItem);
    on<RemoveScannedItem>(_onRemoveScannedItem);
    on<AddScannedItem>(_onAddScannedItem);
    on<FinalizeAssignment>(_onFinalizeAssignment);
  }

  void _onLoadScannedItems(
    LoadScannedItems event,
    Emitter<AssignmentState> emit,
  ) {
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
        receiptTax: event.receipt.detectedTax,
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
      emit(state.copyWith(errorMessage: '"$name" udah ada di daftar.'));
      return;
    }

    final newPerson = Person(
      id: 'person_${state.persons.length}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
    );

    emit(
      state.copyWith(
        persons: [...state.persons, newPerson],
        clearError: true,
        clearFinalized: true,
      ),
    );
  }

  void _onRemovePerson(RemovePerson event, Emitter<AssignmentState> emit) {
    final updatedPersons = state.persons
        .where((p) => p.id != event.personId)
        .toList();

    final updatedItems = state.items.map((item) {
      if (item.isAssignedTo(event.personId)) {
        return item.copyWith(
          assignedPersonIds: item.assignedPersonIds
              .where((id) => id != event.personId)
              .toList(),
        );
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        persons: updatedPersons,
        items: updatedItems,
        clearFinalized: true,
        clearError: true,
      ),
    );
  }

  void _onToggleItemAssignment(
    ToggleItemAssignment event,
    Emitter<AssignmentState> emit,
  ) {
    final updatedItems = state.items.map((item) {
      if (item.id != event.itemId) return item;

      if (item.isAssignedTo(event.personId)) {
        return item.copyWith(
          assignedPersonIds: item.assignedPersonIds
              .where((id) => id != event.personId)
              .toList(),
        );
      }
      return item.copyWith(
        assignedPersonIds: [...item.assignedPersonIds, event.personId],
      );
    }).toList();

    emit(state.copyWith(items: updatedItems, clearFinalized: true));
  }

  void _onUpdateScannedItem(
    UpdateScannedItem event,
    Emitter<AssignmentState> emit,
  ) {
    final updatedItems = state.items
        .map(
          (i) => i.id == event.itemId
              ? i.copyWith(name: event.name, price: event.price)
              : i,
        )
        .toList();
    emit(
      state.copyWith(
        items: updatedItems,
        clearFinalized: true,
        clearError: true,
      ),
    );
  }

  void _onRemoveScannedItem(
    RemoveScannedItem event,
    Emitter<AssignmentState> emit,
  ) {
    final updatedItems = state.items
        .where((i) => i.id != event.itemId)
        .toList();
    emit(
      state.copyWith(
        items: updatedItems,
        clearFinalized: true,
        clearError: true,
      ),
    );
  }

  void _onAddScannedItem(AddScannedItem event, Emitter<AssignmentState> emit) {
    final item = AssignableItem(
      id: 'item_manual_${DateTime.now().microsecondsSinceEpoch}',
      name: event.name,
      price: event.price,
    );
    emit(
      state.copyWith(
        items: [...state.items, item],
        clearFinalized: true,
        clearError: true,
      ),
    );
  }

  void _onFinalizeAssignment(
    FinalizeAssignment event,
    Emitter<AssignmentState> emit,
  ) {
    final allItems = List<AssignableItem>.from(state.items);
    if (allItems.isEmpty) {
      emit(state.copyWith(errorMessage: 'Belum ada item yang bisa dihitung.'));
      return;
    }

    final allAssigned = allItems.every((i) => !i.isUnassigned);
    if (!allAssigned) {
      final unassignedCount = allItems.where((i) => i.isUnassigned).length;
      emit(
        state.copyWith(
          errorMessage:
              'Masih ada $unassignedCount item yang belum kebagi. Bagi semua dulu, ya.',
        ),
      );
      return;
    }

    final orders = <PersonOrder>[];
    for (final person in state.persons) {
      final personItems = <OrderItem>[];
      for (final item in allItems.where((i) => i.isAssignedTo(person.id))) {
        final count = item.assignedPersonIds.length;
        if (count <= 1) {
          personItems.add(OrderItem(name: item.name, price: item.price));
          continue;
        }
        // Bagi rata; sisa pembulatan dibebankan ke orang-orang pertama di
        // daftar supaya total semua bagian tetap sama persis dengan harga item.
        final base = (item.price / count).floorToDouble();
        final remainder = (item.price - base * count).round();
        final idx = item.assignedPersonIds.indexOf(person.id);
        final share = base + (idx < remainder ? 1 : 0);
        personItems.add(
          OrderItem(name: '${item.name} (1/$count)', price: share),
        );
      }

      if (personItems.isNotEmpty) {
        orders.add(
          PersonOrder(id: person.id, name: person.name, items: personItems),
        );
      }
    }

    emit(
      state.copyWith(
        status: AssignmentStatus.finalized,
        finalizedOrders: orders,
        clearError: true,
      ),
    );
  }
}
