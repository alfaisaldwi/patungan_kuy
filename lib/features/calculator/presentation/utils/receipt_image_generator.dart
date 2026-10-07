import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/bill_result.dart';
import '../../domain/entities/person_order.dart';
import '../widgets/receipt_image_view.dart';

/// Membuat gambar struk panjang (lebar seukuran layar HP, tinggi mengikuti
/// isi) lalu membagikannya.
class ReceiptImageGenerator {
  ReceiptImageGenerator._();

  /// Batas aman tinggi tekstur GPU.
  static const double _maxPixelHeight = 8000;

  static Future<bool> shareReceipt({
    required BuildContext context,
    required BillResult result,
    required List<PersonOrder> orders,
    String fileName = 'PatunganKuy_Receipt',
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final width = MediaQuery.sizeOf(context).width.clamp(320.0, 430.0);
    final boundaryKey = GlobalKey();
    OverlayEntry? entry;

    try {
      await Future.wait([
        precacheImage(const AssetImage(ReceiptImageView.logoDark), context),
        precacheImage(const AssetImage(ReceiptImageView.logoLight), context),
      ]);

      // Dirender di luar layar dengan tinggi tak terbatas.
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -width * 2,
          top: 0,
          width: width,
          child: IgnorePointer(
            // OverflowBox tidak boleh ukurannya tak terbatas, jadi diberi kotak
            // induk berukuran tetap; isi struk tetap leluasa meluap ke bawah.
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
      if (boundary == null) {
        _showSnackBar(context, 'Gagal membuat gambar struk.');
        return false;
      }

      final ratio = (_maxPixelHeight / boundary.size.height).clamp(1.5, 3.0);
      final ui.Image image = await boundary.toImage(pixelRatio: ratio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        if (context.mounted)
          _showSnackBar(context, 'Gagal memproses gambar struk.');
        return false;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName.png';
      await File(path).writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([
        XFile(path, mimeType: 'image/png'),
      ], text: 'Struk patungan dari PatunganKuy');
      return true;
    } catch (e) {
      if (context.mounted) _showSnackBar(context, 'Gagal membagikan struk: $e');
      return false;
    } finally {
      entry?.remove();
      entry?.dispose();
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
