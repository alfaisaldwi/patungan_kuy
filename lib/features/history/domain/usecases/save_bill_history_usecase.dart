import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_history.dart';
import '../repositories/bill_history_repository.dart';

class SaveBillHistoryUseCase {
  final BillHistoryRepository repository;

  SaveBillHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call(BillHistory entry) => repository.save(entry);
}
