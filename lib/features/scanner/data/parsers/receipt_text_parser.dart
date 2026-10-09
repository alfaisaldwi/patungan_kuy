import '../../../calculator/domain/entities/person_order.dart';
import '../../domain/entities/parsed_receipt.dart';

enum _PendingLabel { subtotal, discount, fee, total }

typedef _ItemLine = ({String name, int qty, double price});

class ReceiptTextParser {
  const ReceiptTextParser();

  static final RegExp _itemPattern = RegExp(r'^(\d+)\s*[xX]\s*(.+)');

  static final RegExp _rpPricePattern = RegExp(r'[Rr][Pp]\s*([\d\.]+)');

  static final RegExp _numericPricePattern = RegExp(
    r'\b(\d{1,3}(?:\.\d{3})+(?:[.,]\d{1,3})?)\b',
  );

  static final RegExp _negativePricePattern = RegExp(
    r'-\s*(?:[Rr][Pp]\s*)?([\d\.]+)',
  );

  static final RegExp _feeLabelPattern = RegExp(
    r'^biaya\b(?!-)|pengiriman|layanan|kemasan|ongkir|ongkos|antar|delivery|platform|aplikasi|penanganan',
    caseSensitive: false,
  );

  static final RegExp _discountLabelPattern = RegExp(
    r'voucher|diskon|discount|promo|potongan',
    caseSensitive: false,
  );

  static final RegExp _subtotalLabelPattern = RegExp(
    r'subtotal|sub\s*total|harga\s*makanan',
    caseSensitive: false,
  );

  static final RegExp _totalLabelPattern = RegExp(
    r'^total\b|pembayaran|grand\s*total|tagihan|total\s*pesanan|total\s*bayar',
    caseSensitive: false,
  );

  ParsedReceipt parse(List<String> lines) {
    final itemLines = <_ItemLine>[];
    double totalFees = 0;
    double totalDiscount = 0;
    double? subtotal;

    String? pendingItemName;
    int pendingQuantity = 0;
    double? pendingItemPrice;
    _PendingLabel? pendingLabel;

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      final priceOnLine = _extractPriceFromLine(trimmed);
      final hasNegative = _lineHasNegativePrice(trimmed);

      if (_isPriceOnlyLine(trimmed)) {
        if (pendingLabel != null) {
          switch (pendingLabel) {
            case _PendingLabel.subtotal:
              if (!hasNegative && priceOnLine != null) {
                subtotal = (subtotal ?? 0) + priceOnLine;
              }
              break;
            case _PendingLabel.discount:
              totalDiscount += priceOnLine ?? 0;
              break;
            case _PendingLabel.fee:
              if (priceOnLine != null) totalFees += priceOnLine;
              break;
            case _PendingLabel.total:
              break;
          }
          pendingLabel = null;
          continue;
        }

        if (pendingItemName != null && pendingItemPrice == null) {
          pendingItemPrice = priceOnLine;
          continue;
        }

        if (hasNegative) {
          totalDiscount += priceOnLine ?? 0;
          continue;
        }

        continue;
      }

      final itemMatch = _itemPattern.firstMatch(trimmed);
      if (itemMatch != null) {
        _flushPendingItem(
          itemLines,
          pendingItemName,
          pendingQuantity,
          pendingItemPrice,
        );

        pendingLabel = null;
        pendingQuantity = int.tryParse(itemMatch.group(1)!) ?? 1;

        var rawName = itemMatch.group(2)!.trim();
        rawName = _stripTrailingPrice(rawName);
        pendingItemName = rawName;

        pendingItemPrice = priceOnLine;
        continue;
      }

      final isSummary =
          _subtotalLabelPattern.hasMatch(trimmed) ||
          _discountLabelPattern.hasMatch(trimmed) ||
          _feeLabelPattern.hasMatch(trimmed) ||
          _totalLabelPattern.hasMatch(trimmed);

      if (isSummary &&
          pendingItemName != null &&
          pendingQuantity > 0 &&
          pendingItemPrice != null) {
        _flushPendingItem(
          itemLines,
          pendingItemName,
          pendingQuantity,
          pendingItemPrice,
        );
        pendingItemName = null;
        pendingItemPrice = null;
        pendingQuantity = 0;
      }

      if (_discountLabelPattern.hasMatch(trimmed)) {
        if (priceOnLine != null) {
          totalDiscount += priceOnLine;
        } else {
          pendingLabel = _PendingLabel.discount;
        }
        continue;
      }

      if (_subtotalLabelPattern.hasMatch(trimmed)) {
        if (priceOnLine != null) {
          subtotal = (subtotal ?? 0) + priceOnLine;
        } else {
          pendingLabel = _PendingLabel.subtotal;
        }
        continue;
      }

      if (_feeLabelPattern.hasMatch(trimmed)) {
        if (priceOnLine != null) {
          totalFees += priceOnLine;
        } else {
          pendingLabel = _PendingLabel.fee;
        }
        continue;
      }

      if (_totalLabelPattern.hasMatch(trimmed)) {
        pendingLabel = priceOnLine != null ? null : _PendingLabel.total;
        continue;
      }

      if (priceOnLine == null) continue;

      if (pendingItemName != null && pendingItemPrice == null) {
        pendingItemPrice = priceOnLine;
      }
      pendingLabel = null;
    }

    _flushPendingItem(
      itemLines,
      pendingItemName,
      pendingQuantity,
      pendingItemPrice,
    );

    final orders = _toOrderItems(
      itemLines,
      subtotal,
    ).map((item) => ExtractedOrder(name: item.name, items: [item])).toList();

    return ParsedReceipt(
      orders: orders,
      detectedSubtotal: subtotal,
      detectedDeliveryFee: totalFees,
      detectedDiscount: totalDiscount,
    );
  }

  double? _extractPriceFromLine(String line) {
    final rpMatch = _rpPricePattern.allMatches(line).toList();
    if (rpMatch.isNotEmpty) {
      final raw = rpMatch.last.group(1)!;
      return _parseRupiah(raw);
    }

    final numMatch = _numericPricePattern.allMatches(line).toList();
    if (numMatch.isNotEmpty) {
      final raw = numMatch.last.group(1)!;
      return _parseRupiah(raw);
    }

    return null;
  }

  bool _lineHasNegativePrice(String line) {
    if (_negativePricePattern.hasMatch(line)) return true;

    final trimmed = line.trim();
    return trimmed.startsWith('-') && RegExp(r'\d').hasMatch(trimmed);
  }

  String _stripTrailingPrice(String name) {
    var cleaned = name.replaceAll(_rpPricePattern, '').trim();

    cleaned = cleaned.replaceAll(_numericPricePattern, '').trim();

    cleaned = cleaned.replaceAll(RegExp(r'[;,]+$'), '').trim();
    return cleaned;
  }

  void _flushPendingItem(
    List<_ItemLine> lines,
    String? name,
    int qty,
    double? price,
  ) {
    if (name == null || qty <= 0) return;
    lines.add((name: name, qty: qty, price: price ?? 0));
  }

  List<OrderItem> _toOrderItems(List<_ItemLine> lines, double? subtotal) {
    var pricesArePerUnit = false;
    if (subtotal != null) {
      final asLineTotal = lines.fold<double>(0, (s, l) => s + l.price);
      final asPerUnit = lines.fold<double>(0, (s, l) => s + l.price * l.qty);
      pricesArePerUnit =
          (asPerUnit - subtotal).abs() < (asLineTotal - subtotal).abs();
    }

    return [
      for (final line in lines)
        for (var i = 0; i < line.qty; i++)
          OrderItem(
            name: line.qty > 1 ? '${line.name} (${i + 1})' : line.name,
            price: pricesArePerUnit ? line.price : line.price / line.qty,
          ),
    ];
  }

  bool _isPriceOnlyLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;

    if (_extractPriceFromLine(trimmed) == null) return false;

    if (_itemPattern.hasMatch(trimmed)) return false;
    if (_feeLabelPattern.hasMatch(trimmed)) return false;
    if (_discountLabelPattern.hasMatch(trimmed)) return false;
    if (_subtotalLabelPattern.hasMatch(trimmed)) return false;
    if (_totalLabelPattern.hasMatch(trimmed)) return false;

    final rpIdx = trimmed.indexOf(RegExp(r'[Rr][Pp]'));
    final numIdx = trimmed.indexOf(RegExp(r'\d{1,3}(?:\.\d{3})'));
    var firstIdx = rpIdx >= 0 ? rpIdx : numIdx;
    if (firstIdx < 0) firstIdx = 0;

    final before = trimmed.substring(0, firstIdx).trim();

    if (before.isEmpty || before == '-' || before == '- ') return true;
    if (before.length <= 4) return true;

    return false;
  }

  double _parseRupiah(String raw) {
    var s = raw.replaceAll('.', '');
    if (s.contains(',')) {
      final lastComma = s.lastIndexOf(',');
      final afterComma = s.substring(lastComma + 1);
      if (afterComma.length <= 2) {
        s = '${s.substring(0, lastComma)}.$afterComma';
      } else {
        s = s.replaceAll(',', '');
      }
    }
    return double.tryParse(s) ?? 0.0;
  }
}
