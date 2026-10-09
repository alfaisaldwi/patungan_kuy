import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/parsed_receipt.dart';
import '../../domain/repositories/receipt_scanner_repository.dart';
import '../datasources/receipt_ai_datasource.dart';
import '../datasources/receipt_scanner_datasource.dart';
import '../parsers/ai_receipt_mapper.dart';
import '../parsers/receipt_text_parser.dart';

class ReceiptScannerRepositoryImpl implements ReceiptScannerRepository {
  final ReceiptScannerDataSource _dataSource;
  final ReceiptAiDataSource? _aiDataSource;
  final ReceiptTextParser _parser;
  final AiReceiptMapper _aiMapper;

  ReceiptScannerRepositoryImpl(
    this._dataSource, {
    ReceiptAiDataSource? aiDataSource,
    ReceiptTextParser parser = const ReceiptTextParser(),
    AiReceiptMapper aiMapper = const AiReceiptMapper(),
  }) : _aiDataSource = aiDataSource,
       _parser = parser,
       _aiMapper = aiMapper;

  @override
  Future<Either<Failure, ParsedReceipt>> extractFromImage(
    String imagePath,
  ) async {
    final ai = _aiDataSource;
    if (ai != null && ai.isEnabled) {
      try {
        final receipt = _aiMapper.map(await ai.scan(imagePath));
        if (receipt == null) {
          return const Left(
            CalculatorFailure(
              'Kayaknya ini bukan struk. Coba foto struk atau rincian pesanannya, ya.',
            ),
          );
        }
        return Right(receipt);
      } catch (e) {
        debugPrint('AI scan failed, falling back to ML Kit: $e');
      }
    }

    return _extractWithMlKit(imagePath);
  }

  Future<Either<Failure, ParsedReceipt>> _extractWithMlKit(
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

      return Right(_parser.parse(lines));
    } catch (e) {
      return Left(CalculatorFailure('Gagal scan struk: $e'));
    }
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
      debugPrint('DEBUG RECONSTRUCTED LINE: $l');
    }

    return mergedLines;
  }
}
