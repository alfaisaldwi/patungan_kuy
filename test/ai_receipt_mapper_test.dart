import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/features/scanner/data/parsers/ai_receipt_mapper.dart';

const _mapper = AiReceiptMapper();

void main() {
  test('qty dipecah per porsi, biaya & diskon dijumlah', () {
    final r = _mapper.map({
      'is_receipt': true,
      'items': [
        {'name': 'Ice Kopi Susu Keluarga', 'quantity': 2, 'line_total': 37000},
        {'name': 'Pao Coklat Besar', 'quantity': 1, 'line_total': 10500},
      ],
      'fees': [
        {'label': 'Biaya Pengiriman', 'amount': 6000},
        {'label': 'Biaya Layanan', 'amount': 4500},
      ],
      'discounts': [
        {'label': 'Voucher Diskon', 'amount': 10000},
      ],
      'tax': null,
      'subtotal': 47500,
      'total': 48000,
    })!;

    final items = [
      for (final o in r.orders)
        for (final i in o.items) (i.name, i.price),
    ];
    expect(items, [
      ('Ice Kopi Susu Keluarga (1)', 18500),
      ('Ice Kopi Susu Keluarga (2)', 18500),
      ('Pao Coklat Besar', 10500),
    ]);
    expect(r.detectedSubtotal, 47500);
    expect(r.detectedDeliveryFee, 10500);
    expect(r.detectedDiscount, 10000);
    expect(r.detectedTax, isNull);
  });

  test('diskon negatif tetap dihitung positif', () {
    final r = _mapper.map({
      'is_receipt': true,
      'items': [],
      'fees': [],
      'discounts': [
        {'label': 'Promo', 'amount': -5000},
      ],
      'tax': 2500,
      'subtotal': null,
      'total': null,
    })!;

    expect(r.detectedDiscount, 5000);
    expect(r.detectedTax, 2500);
  });

  test('bukan struk -> null', () {
    expect(
      _mapper.map({
        'is_receipt': false,
        'items': [],
        'fees': [],
        'discounts': [],
        'tax': null,
        'subtotal': null,
        'total': null,
      }),
      isNull,
    );
  });
}
