import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;

  const Person({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Satu item bisa dimiliki beberapa orang sekaligus (patungan per item);
/// harganya dibagi rata ke semua yang ikut.
class AssignableItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final List<String> assignedPersonIds;

  const AssignableItem({
    required this.id,
    required this.name,
    required this.price,
    this.assignedPersonIds = const [],
  });

  bool isAssignedTo(String personId) => assignedPersonIds.contains(personId);

  bool get isUnassigned => assignedPersonIds.isEmpty;

  bool get isShared => assignedPersonIds.length > 1;

  double get sharePrice =>
      assignedPersonIds.isEmpty ? price : price / assignedPersonIds.length;

  AssignableItem copyWith({
    String? name,
    double? price,
    List<String>? assignedPersonIds,
  }) {
    return AssignableItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      assignedPersonIds: assignedPersonIds ?? this.assignedPersonIds,
    );
  }

  @override
  List<Object?> get props => [id, name, price, assignedPersonIds];
}
