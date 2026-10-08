import 'package:equatable/equatable.dart';

import '../../../calculator/domain/entities/person_order.dart';

class ExtractedOrder extends Equatable {
  final String name;
  final List<OrderItem> items;

  const ExtractedOrder({required this.name, required this.items});

  @override
  List<Object?> get props => [name, items];
}

class ParsedReceipt extends Equatable {
  final List<ExtractedOrder> orders;
  final double? detectedSubtotal;
  final double? detectedTax;
  final double? detectedDeliveryFee;
  final double? detectedDiscount;

  const ParsedReceipt({
    this.orders = const [],
    this.detectedSubtotal,
    this.detectedTax,
    this.detectedDeliveryFee,
    this.detectedDiscount,
  });

  @override
  List<Object?> get props => [
    orders,
    detectedSubtotal,
    detectedTax,
    detectedDeliveryFee,
    detectedDiscount,
  ];
}
