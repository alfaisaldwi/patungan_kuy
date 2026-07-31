part of 'assignment_bloc.dart';

sealed class AssignmentEvent extends Equatable {
  const AssignmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadScannedItems extends AssignmentEvent {
  final ParsedReceipt receipt;

  const LoadScannedItems({required this.receipt});

  @override
  List<Object?> get props => [receipt];
}

class AddPerson extends AssignmentEvent {
  final String name;

  const AddPerson({required this.name});

  @override
  List<Object?> get props => [name];
}

class RemovePerson extends AssignmentEvent {
  final String personId;

  const RemovePerson({required this.personId});

  @override
  List<Object?> get props => [personId];
}

class ToggleItemAssignment extends AssignmentEvent {
  final String itemId;
  final String personId;

  const ToggleItemAssignment({required this.itemId, required this.personId});

  @override
  List<Object?> get props => [itemId, personId];
}

class FinalizeAssignment extends AssignmentEvent {
  const FinalizeAssignment();
}
