part of 'calculator_bloc.dart';

enum CalculatorStatus { initial, calculated, error }

class CalculatorState extends Equatable {
  final List<PersonOrder> orders;
  final double taxFee;
  final double deliveryFee;
  final double discountAmount;
  final bool isDiscountPercentage;
  final BillResult? result;
  final CalculatorStatus status;
  final String? errorMessage;

  const CalculatorState({
    this.orders = const [],
    this.taxFee = 0.0,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    this.isDiscountPercentage = false,
    this.result,
    this.status = CalculatorStatus.initial,
    this.errorMessage,
  });

  CalculatorState copyWith({
    List<PersonOrder>? orders,
    double? taxFee,
    double? deliveryFee,
    double? discountAmount,
    bool? isDiscountPercentage,
    BillResult? result,
    CalculatorStatus? status,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return CalculatorState(
      orders: orders ?? this.orders,
      taxFee: taxFee ?? this.taxFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      result: clearResult ? null : (result ?? this.result),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    taxFee,
    deliveryFee,
    discountAmount,
    isDiscountPercentage,
    result,
    status,
    errorMessage,
  ];
}
