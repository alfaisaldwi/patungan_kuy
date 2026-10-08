part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  const LoadHistory();
}

class DeleteHistoryEntry extends HistoryEvent {
  final String id;

  const DeleteHistoryEntry({required this.id});

  @override
  List<Object?> get props => [id];
}

class RestoreHistoryEntry extends HistoryEvent {
  final BillHistory entry;
  final int index;

  const RestoreHistoryEntry({required this.entry, required this.index});

  @override
  List<Object?> get props => [entry, index];
}

class ClearHistory extends HistoryEvent {
  const ClearHistory();
}
