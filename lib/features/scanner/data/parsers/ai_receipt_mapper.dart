import '../../../calculator/domain/entities/person_order.dart';
import '../../domain/entities/parsed_receipt.dart';

class AiReceiptMapper {
  const AiReceiptMapper();

  ParsedReceipt? map(Map<String, dynamic> json) {
    if (json['is_receipt'] != true) return null;

    final items = <OrderItem>[];
    for (final raw in (json['items'] as List? ?? const [])) {
      final item = raw as Map<String, dynamic>;
      final name = (item['name'] as String? ?? '').trim();
      final qty = (item['quantity'] as num? ?? 1).toInt().clamp(1, 99);
      final lineTotal = (item['line_total'] as num? ?? 0).toDouble();
      if (name.isEmpty) continue;

      for (var i = 0; i < qty; i++) {
        items.add(
          OrderItem(
            name: qty > 1 ? '$name (${i + 1})' : name,
            price: lineTotal / qty,
          ),
        );
      }
    }

    return ParsedReceipt(
      orders: [
        for (final item in items)
          ExtractedOrder(name: item.name, items: [item]),
      ],
      detectedSubtotal: (json['subtotal'] as num?)?.toDouble(),
      detectedTax: (json['tax'] as num?)?.toDouble(),
      detectedDeliveryFee: _sumAmounts(json['fees']),
      detectedDiscount: _sumAmounts(json['discounts']),
    );
  }

  double _sumAmounts(Object? list) => (list as List? ?? const []).fold(
    0,
    (sum, e) => sum + ((e as Map<String, dynamic>)['amount'] as num).abs(),
  );
}
