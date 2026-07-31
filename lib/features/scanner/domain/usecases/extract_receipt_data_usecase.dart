import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/parsed_receipt.dart';
import '../repositories/receipt_scanner_repository.dart';

class ExtractReceiptDataUseCase {
  final ReceiptScannerRepository repository;

  ExtractReceiptDataUseCase(this.repository);

  Future<Either<Failure, ParsedReceipt>> call(String imagePath) {
    return repository.extractFromImage(imagePath);
  }
}
