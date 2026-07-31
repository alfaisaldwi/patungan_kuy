import 'package:equatable/equatable.dart';

class CalculatedBill extends Equatable {
  final String personId;
  final String name;
  final double originalPrice;
  final double proportionalFee;
  final double proportionalDiscount;
  final double finalPayable;

  const CalculatedBill({
    required this.personId,
    required this.name,
    required this.originalPrice,
    required this.proportionalFee,
    required this.proportionalDiscount,
    required this.finalPayable,
  });

  @override
  List<Object?> get props => [
        personId,
        name,
        originalPrice,
        proportionalFee,
        proportionalDiscount,
        finalPayable,
      ];
}
