part of 'assignment_bloc.dart';

enum AssignmentStatus { initial, editing, finalized }

class AssignmentState extends Equatable {
  final List<Person> persons;
  final List<AssignableItem> items;
  final AssignmentStatus status;
  final String? errorMessage;

  final List<PersonOrder>? finalizedOrders;

  final double? receiptSubtotal;
  final double? receiptTax;
  final double? receiptDeliveryFee;
  final double? receiptDiscount;

  const AssignmentState({
    this.persons = const [],
    this.items = const [],
    this.status = AssignmentStatus.initial,
    this.errorMessage,
    this.finalizedOrders,
    this.receiptSubtotal,
    this.receiptTax,
    this.receiptDeliveryFee,
    this.receiptDiscount,
  });

  AssignmentState copyWith({
    List<Person>? persons,
    List<AssignableItem>? items,
    AssignmentStatus? status,
    String? errorMessage,
    List<PersonOrder>? finalizedOrders,
    double? receiptSubtotal,
    double? receiptTax,
    double? receiptDeliveryFee,
    double? receiptDiscount,
    bool clearError = false,
    bool clearFinalized = false,
  }) {
    return AssignmentState(
      persons: persons ?? this.persons,
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      finalizedOrders: clearFinalized
          ? null
          : (finalizedOrders ?? this.finalizedOrders),
      receiptSubtotal: receiptSubtotal ?? this.receiptSubtotal,
      receiptTax: receiptTax ?? this.receiptTax,
      receiptDeliveryFee: receiptDeliveryFee ?? this.receiptDeliveryFee,
      receiptDiscount: receiptDiscount ?? this.receiptDiscount,
    );
  }

  double get unassignedTotal =>
      items.where((i) => i.isUnassigned).fold(0, (s, i) => s + i.price);

  double get itemsTotal => items.fold(0, (s, i) => s + i.price);

  double assignedTotalFor(String personId) => items
      .where((i) => i.isAssignedTo(personId))
      .fold(0, (s, i) => s + i.sharePrice);

  @override
  List<Object?> get props => [
    persons,
    items,
    status,
    errorMessage,
    finalizedOrders,
    receiptSubtotal,
    receiptTax,
    receiptDeliveryFee,
    receiptDiscount,
  ];
}
