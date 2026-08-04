import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_history.dart';

abstract class BillHistoryRepository {
  /// Returns all saved bills, newest first.
  Future<Either<Failure, List<BillHistory>>> getAll();

  Future<Either<Failure, void>> save(BillHistory entry);

  Future<Either<Failure, void>> delete(String id);

  Future<Either<Failure, void>> clear();
}
