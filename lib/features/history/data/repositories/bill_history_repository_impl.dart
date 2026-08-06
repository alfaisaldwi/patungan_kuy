import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/bill_history.dart';
import '../../domain/repositories/bill_history_repository.dart';
import '../datasources/bill_history_datasource.dart';

class BillHistoryRepositoryImpl implements BillHistoryRepository {
  final BillHistoryDataSource _dataSource;

  BillHistoryRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<BillHistory>>> getAll() async {
    try {
      return Right(_dataSource.getAll());
    } catch (e) {
      return Left(HistoryFailure('Gagal memuat riwayat: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> save(BillHistory entry) async {
    try {
      await _dataSource.save(entry);
      return const Right(null);
    } catch (e) {
      return Left(HistoryFailure('Gagal menyimpan riwayat: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(HistoryFailure('Gagal menghapus riwayat: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clear() async {
    try {
      await _dataSource.clear();
      return const Right(null);
    } catch (e) {
      return Left(HistoryFailure('Gagal menghapus semua riwayat: $e'));
    }
  }
}
