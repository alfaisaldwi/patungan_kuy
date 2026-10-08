import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/error/failures.dart';
import '../../../calculator/domain/entities/person_order.dart';
import '../../domain/entities/parsed_receipt.dart';
import '../../domain/repositories/receipt_scanner_repository.dart';
import '../datasources/receipt_scanner_datasource.dart';

enum _PendingLabel { subtotal, discount, fee, total }

class ReceiptScannerRepositoryImpl implements ReceiptScannerRepository {
  final ReceiptScannerDataSource _dataSource;

  ReceiptScannerRepositoryImpl(this._dataSource);

  static final RegExp _itemPattern = RegExp(r'^(\d+)\s*[xX]\s*(.+)');

  static final RegExp _rpPricePattern = RegExp(r'[Rr][Pp]\s*([\d\.]+)');

  static final RegExp _numericPricePattern = RegExp(
    r'\b(\d{1,3}(?:\.\d{3})+(?:[.,]\d{1,3})?)\b',
  );

  static final RegExp _negativePricePattern = RegExp(
    r'-\s*(?:[Rr][Pp]\s*)?([\d\.]+)',
  );

  static final RegExp _feeLabelPattern = RegExp(
    r'pengiriman|layanan|pengemasan|ongkir|antar|delivery|platform|aplikasi|penanganan',
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

  @override
  Future<Either<Failure, ParsedReceipt>> extractFromImage(
    String imagePath,
  ) async {
    try {
      final recognizedText = await _dataSource.recognizeText(imagePath);

      final lines = _extractLines(recognizedText);
      if (lines.isEmpty) {
        return const Left(
          CalculatorFailure(
            'Nggak ada teks yang kebaca. Coba foto yang lebih jelas, ya.',
          ),
        );
      }

      return _buildParsedReceipt(lines);
    } catch (e) {
      return Left(CalculatorFailure('Gagal scan struk: $e'));
    }
  }

  Either<Failure, ParsedReceipt> _buildParsedReceipt(List<String> lines) {
    final orderItems = <OrderItem>[];
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
          orderItems,
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
          orderItems,
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
      orderItems,
      pendingItemName,
      pendingQuantity,
      pendingItemPrice,
    );

    final orders = orderItems
        .map((item) => ExtractedOrder(name: item.name, items: [item]))
        .toList();

    return Right(
      ParsedReceipt(
        orders: orders,
        detectedSubtotal: subtotal,
        detectedDeliveryFee: totalFees,
        detectedDiscount: totalDiscount,
      ),
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
    List<OrderItem> items,
    String? name,
    int qty,
    double? price,
  ) {
    if (name == null || qty <= 0) return;
    final p = price ?? 0;
    final perItem = p / qty;
    final isLikelyTotal = (p % qty == 0) && (perItem % 500 == 0) && qty > 1;

    if (isLikelyTotal) {
      for (int i = 0; i < qty; i++) {
        items.add(OrderItem(name: '$name (${i + 1})', price: perItem));
      }
    } else {
      for (int i = 0; i < qty; i++) {
        final label = qty > 1 ? '$name (${i + 1})' : name;
        items.add(OrderItem(name: label, price: p));
      }
    }
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
        s = s.substring(0, lastComma) + '.' + afterComma;
      } else {
        s = s.replaceAll(',', '');
      }
    }
    return double.tryParse(s) ?? 0.0;
  }

  List<String> _extractLines(RecognizedText recognizedText) {
    final allTextLines = <TextLine>[];

    for (final block in recognizedText.blocks) {
      allTextLines.addAll(block.lines);
    }

    allTextLines.sort((a, b) {
      final centerA = a.boundingBox.top + (a.boundingBox.height / 2);
      final centerB = b.boundingBox.top + (b.boundingBox.height / 2);
      return centerA.compareTo(centerB);
    });

    List<String> mergedLines = [];
    if (allTextLines.isEmpty) return mergedLines;

    List<TextLine> currentGroup = [allTextLines.first];
    double currentCenter =
        allTextLines.first.boundingBox.top +
        (allTextLines.first.boundingBox.height / 2);

    double threshold = allTextLines.first.boundingBox.height * 0.5;

    for (int i = 1; i < allTextLines.length; i++) {
      final line = allTextLines[i];
      final center = line.boundingBox.top + (line.boundingBox.height / 2);

      if ((center - currentCenter).abs() < threshold) {
        currentGroup.add(line);
      } else {
        currentGroup.sort(
          (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
        );
        mergedLines.add(currentGroup.map((e) => e.text).join(' '));

        currentGroup = [line];
        currentCenter = center;
        threshold = line.boundingBox.height * 0.5;
      }
    }

    if (currentGroup.isNotEmpty) {
      currentGroup.sort(
        (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
      );
      mergedLines.add(currentGroup.map((e) => e.text).join(' '));
    }

    for (var l in mergedLines) {
      print('DEBUG RECONSTRUCTED LINE: $l');
    }

    return mergedLines;
  }
}
