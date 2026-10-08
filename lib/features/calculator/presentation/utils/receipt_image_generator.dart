import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bill_result.dart';
import '../../domain/entities/person_order.dart';
import '../widgets/receipt_image_view.dart';

enum GallerySaveResult { saved, denied, failed }

class ReceiptImageGenerator {
  ReceiptImageGenerator._();

  static const double _maxPixelHeight = 8000;
  static const String _fileName = 'PatunganKuy_Receipt';

  static Future<Uint8List?> render({
    required BuildContext context,
    required BillResult result,
    required List<PersonOrder> orders,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final width = MediaQuery.sizeOf(context).width.clamp(320.0, 430.0);
    final precache = Future.wait([
      precacheImage(const AssetImage(ReceiptImageView.logoDark), context),
      precacheImage(const AssetImage(ReceiptImageView.logoLight), context),
    ]);
    final boundaryKey = GlobalKey();
    OverlayEntry? entry;

    try {
      await precache;

      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -width * 2,
          top: 0,
          width: width,
          child: IgnorePointer(
            child: SizedBox(
              height: 1,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Material(
                    color: Colors.transparent,
                    child: ReceiptImageView(
                      result: result,
                      orders: orders,
                      width: width,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(entry);

      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ratio = (_maxPixelHeight / boundary.size.height).clamp(1.5, 3.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } finally {
      entry?.remove();
      entry?.dispose();
    }
  }

  static Future<bool> share({
    required BuildContext context,
    required BillResult result,
    required List<PersonOrder> orders,
  }) async {
    try {
      final bytes = await render(
        context: context,
        result: result,
        orders: orders,
      );
      if (bytes == null) return false;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$_fileName.png';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(path, mimeType: 'image/png'),
      ], text: 'Struk patungan dari PatunganKuy');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<GallerySaveResult> saveToGallery({
    required BuildContext context,
    required BillResult result,
    required List<PersonOrder> orders,
  }) async {
    try {
      final rendering = render(
        context: context,
        result: result,
        orders: orders,
      );
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        await rendering;
        return GallerySaveResult.denied;
      }
      final bytes = await rendering;
      if (bytes == null) return GallerySaveResult.failed;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await Gal.putImageBytes(bytes, name: '${_fileName}_$stamp');
      return GallerySaveResult.saved;
    } on GalException catch (e) {
      return e.type == GalExceptionType.accessDenied
          ? GallerySaveResult.denied
          : GallerySaveResult.failed;
    } catch (_) {
      return GallerySaveResult.failed;
    }
  }

  static String summaryText(BillResult result) {
    final buffer = StringBuffer()
      ..writeln('🧾 *Patungan ${_formatDate(result.calculatedAt)}*')
      ..writeln('Total: *${AppTheme.formatRupiah(result.grandTotal)}*')
      ..writeln();
    for (final bill in result.calculatedBills) {
      final name = bill.name.trim().isEmpty ? 'Tanpa nama' : bill.name.trim();
      buffer.writeln('• $name: ${AppTheme.formatRupiah(bill.finalPayable)}');
    }
    final extras = <String>[
      if (result.totalFees.round() != 0)
        'biaya ${AppTheme.formatRupiah(result.totalFees)}',
      if (result.totalDiscount.round() != 0)
        'diskon ${AppTheme.formatRupiah(result.totalDiscount)}',
    ];
    if (extras.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Sudah termasuk ${extras.join(' & ')}.');
    }
    buffer
      ..writeln()
      ..write('Dihitung pakai PatunganKuy');
    return buffer.toString();
  }

  static String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
