import 'package:equatable/equatable.dart';

import 'calculated_bill.dart';

class BillResult extends Equatable {
  final List<CalculatedBill> calculatedBills;
  final double totalBase;
  final double totalFees;
  final double totalDiscount;
  final double grandTotal;

  const BillResult({
    required this.calculatedBills,
    required this.totalBase,
    required this.totalFees,
    required this.totalDiscount,
    required this.grandTotal,
  });

  @override
  List<Object?> get props => [
        calculatedBills,
        totalBase,
        totalFees,
        totalDiscount,
        grandTotal,
      ];
}
