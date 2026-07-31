part of 'scanner_bloc.dart';

enum ScannerStatus { initial, loading, success, error }

class ScannerState extends Equatable {
  final ScannerStatus status;
  final ParsedReceipt? parsedReceipt;
  final String? errorMessage;

  const ScannerState({this.status = ScannerStatus.initial, this.parsedReceipt, this.errorMessage});

  ScannerState copyWith({
    ScannerStatus? status,
    ParsedReceipt? parsedReceipt,
    String? errorMessage,
    bool clearParsed = false,
    bool clearError = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      parsedReceipt: clearParsed ? null : (parsedReceipt ?? this.parsedReceipt),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, parsedReceipt, errorMessage];
}
