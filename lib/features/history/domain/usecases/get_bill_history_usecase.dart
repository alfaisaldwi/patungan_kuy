import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_history.dart';
import '../repositories/bill_history_repository.dart';

class GetBillHistoryUseCase {
  final BillHistoryRepository repository;

  GetBillHistoryUseCase(this.repository);

  Future<Either<Failure, List<BillHistory>>> call() => repository.getAll();
}
