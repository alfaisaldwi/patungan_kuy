import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/parsed_receipt.dart';

abstract class ReceiptScannerRepository {
  Future<Either<Failure, ParsedReceipt>> extractFromImage(String imagePath);
}
