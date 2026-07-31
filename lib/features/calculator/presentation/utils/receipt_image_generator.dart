import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptImageGenerator {

  static Future<bool> captureAndShare({
    required BuildContext context,
    required GlobalKey repaintKey,
    String fileName = 'PatunganKuy_Receipt',
  }) async {
    try {

      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _showSnackBar(context, 'Failed to capture receipt: widget not found.');
        return false;
      }

      final ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      );

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar(context, 'Failed to encode receipt image.');
        return false;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/$fileName.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(filePath, mimeType: 'image/png')], text: 'PatunganKuy Bill Receipt');

      return true;
    } catch (e) {
      _showSnackBar(context, 'Error sharing receipt: $e');
      return false;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  }
}
