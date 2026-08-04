import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/bill_history_repository.dart';

class DeleteBillHistoryUseCase {
  final BillHistoryRepository repository;

  DeleteBillHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
