part of 'calculator_bloc.dart';

sealed class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object?> get props => [];
}

class AddPersonOrder extends CalculatorEvent {
  final String name;
  final List<OrderItem> items;

  const AddPersonOrder({required this.name, required this.items});

  @override
  List<Object?> get props => [name, items];
}

class UpdatePersonOrder extends CalculatorEvent {
  final String id;
  final String name;
  final List<OrderItem> items;

  const UpdatePersonOrder({required this.id, required this.name, required this.items});

  @override
  List<Object?> get props => [id, name, items];
}

class RemovePersonOrder extends CalculatorEvent {
  final String id;

  const RemovePersonOrder({required this.id});

  @override
  List<Object?> get props => [id];
}

class UpdateFeesAndDiscount extends CalculatorEvent {
  final double taxFee;
  final double deliveryFee;
  final double discountAmount;
  final bool isDiscountPercentage;

  const UpdateFeesAndDiscount({
    required this.taxFee,
    required this.deliveryFee,
    required this.discountAmount,
    required this.isDiscountPercentage,
  });

  @override
  List<Object?> get props => [taxFee, deliveryFee, discountAmount, isDiscountPercentage];
}

class CalculateBillEvent extends CalculatorEvent {
  const CalculateBillEvent();
}

class RestoreFromHistory extends CalculatorEvent {
  final BillHistory entry;

  const RestoreFromHistory({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class ResetCalculator extends CalculatorEvent {
  const ResetCalculator();
}
