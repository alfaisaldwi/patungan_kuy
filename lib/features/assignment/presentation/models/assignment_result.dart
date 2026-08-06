import '../../../calculator/domain/entities/person_order.dart';

class AssignmentResult {
  final List<PersonOrder> orders;
  final double? subtotal;
  final double? tax;
  final double? deliveryFee;
  final double? discount;

  const AssignmentResult({
    required this.orders,
    this.subtotal,
    this.tax,
    this.deliveryFee,
    this.discount,
  });
}
