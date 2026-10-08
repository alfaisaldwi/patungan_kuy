import '../entities/bill_result.dart';

abstract class CalculatorRepository {
  Future<void> saveResult(BillResult result);

  Future<BillResult?> getLastResult();
}
