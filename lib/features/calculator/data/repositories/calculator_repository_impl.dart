import '../../domain/entities/bill_result.dart';
import '../../domain/repositories/calculator_repository.dart';

class CalculatorRepositoryImpl implements CalculatorRepository {
  BillResult? _cachedResult;

  @override
  Future<void> saveResult(BillResult result) async {
    _cachedResult = result;
  }

  @override
  Future<BillResult?> getLastResult() async {
    return _cachedResult;
  }
}
