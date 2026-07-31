import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;

  const Person({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class AssignableItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? assignedPersonId;

  const AssignableItem({required this.id, required this.name, required this.price, this.assignedPersonId});

  bool isAssignedTo(String personId) => assignedPersonId == personId;

  bool isAssignedToOther(String? personId) {
    if (assignedPersonId == null) return false;
    return assignedPersonId != personId;
  }

  bool get isUnassigned => assignedPersonId == null;

  AssignableItem copyWith({String? assignedPersonId, bool clearAssignment = false}) {
    return AssignableItem(
      id: id,
      name: name,
      price: price,
      assignedPersonId: clearAssignment ? null : (assignedPersonId ?? this.assignedPersonId),
    );
  }

  @override
  List<Object?> get props => [id, name, price, assignedPersonId];
}
