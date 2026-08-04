import '../../../calculator/domain/entities/bill_result.dart';
import '../../../calculator/domain/entities/calculated_bill.dart';
import '../../../calculator/domain/entities/person_order.dart';
import '../../domain/entities/bill_history.dart';

/// JSON (de)serialization for [BillHistory] and its nested entities.
class BillHistoryModel {
  BillHistoryModel._();

  static Map<String, dynamic> toJson(BillHistory entry) {
    return {
      'id': entry.id,
      'createdAt': entry.createdAt.toIso8601String(),
      'taxFee': entry.taxFee,
      'deliveryFee': entry.deliveryFee,
      'discountAmount': entry.discountAmount,
      'isDiscountPercentage': entry.isDiscountPercentage,
      'orders': entry.orders
          .map((o) => {
                'id': o.id,
                'name': o.name,
                'items': o.items.map((i) => {'name': i.name, 'price': i.price}).toList(),
              })
          .toList(),
      'result': {
        'totalBase': entry.result.totalBase,
        'totalFees': entry.result.totalFees,
        'totalDiscount': entry.result.totalDiscount,
        'grandTotal': entry.result.grandTotal,
        'calculatedBills': entry.result.calculatedBills
            .map((b) => {
                  'personId': b.personId,
                  'name': b.name,
                  'originalPrice': b.originalPrice,
                  'proportionalFee': b.proportionalFee,
                  'proportionalDiscount': b.proportionalDiscount,
                  'finalPayable': b.finalPayable,
                })
            .toList(),
      },
    };
  }

  static BillHistory fromJson(Map<String, dynamic> json) {
    final resultJson = json['result'] as Map<String, dynamic>;
    return BillHistory(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      taxFee: (json['taxFee'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      isDiscountPercentage: json['isDiscountPercentage'] as bool,
      orders: (json['orders'] as List)
          .map(
            (o) => PersonOrder(
              id: o['id'] as String,
              name: o['name'] as String,
              items: (o['items'] as List)
                  .map((i) => OrderItem(name: i['name'] as String, price: (i['price'] as num).toDouble()))
                  .toList(),
            ),
          )
          .toList(),
      result: BillResult(
        totalBase: (resultJson['totalBase'] as num).toDouble(),
        totalFees: (resultJson['totalFees'] as num).toDouble(),
        totalDiscount: (resultJson['totalDiscount'] as num).toDouble(),
        grandTotal: (resultJson['grandTotal'] as num).toDouble(),
        calculatedBills: (resultJson['calculatedBills'] as List)
            .map(
              (b) => CalculatedBill(
                personId: b['personId'] as String,
                name: b['name'] as String,
                originalPrice: (b['originalPrice'] as num).toDouble(),
                proportionalFee: (b['proportionalFee'] as num).toDouble(),
                proportionalDiscount: (b['proportionalDiscount'] as num).toDouble(),
                finalPayable: (b['finalPayable'] as num).toDouble(),
              ),
            )
            .toList(),
      ),
    );
  }
}
