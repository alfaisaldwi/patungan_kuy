import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/bill_history_repository.dart';

class ClearBillHistoryUseCase {
  final BillHistoryRepository repository;

  ClearBillHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.clear();
}
