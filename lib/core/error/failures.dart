abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class CalculatorFailure extends Failure {
  const CalculatorFailure(super.message);
}

class HistoryFailure extends Failure {
  const HistoryFailure(super.message);
}
