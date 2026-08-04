import 'package:equatable/equatable.dart';

import '../../../calculator/domain/entities/bill_result.dart';
import '../../../calculator/domain/entities/person_order.dart';

class BillHistory extends Equatable {
  final String id;
  final DateTime createdAt;
  final List<PersonOrder> orders;
  final double taxFee;
  final double deliveryFee;
  final double discountAmount;
  final bool isDiscountPercentage;
  final BillResult result;

  const BillHistory({
    required this.id,
    required this.createdAt,
    required this.orders,
    required this.taxFee,
    required this.deliveryFee,
    required this.discountAmount,
    required this.isDiscountPercentage,
    required this.result,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        orders,
        taxFee,
        deliveryFee,
        discountAmount,
        isDiscountPercentage,
        result,
      ];
}
