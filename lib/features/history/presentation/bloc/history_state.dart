part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<BillHistory> entries;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<BillHistory>? entries,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}
