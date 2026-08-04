import 'package:equatable/equatable.dart';

import 'calculated_bill.dart';

class BillResult extends Equatable {
  final List<CalculatedBill> calculatedBills;
  final double totalBase;
  final double totalFees;
  final double totalDiscount;
  final double grandTotal;
  final DateTime calculatedAt;

  BillResult({
    required this.calculatedBills,
    required this.totalBase,
    required this.totalFees,
    required this.totalDiscount,
    required this.grandTotal,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  @override
  List<Object?> get props => [
        calculatedBills,
        totalBase,
        totalFees,
        totalDiscount,
        grandTotal,
        calculatedAt,
      ];
}
