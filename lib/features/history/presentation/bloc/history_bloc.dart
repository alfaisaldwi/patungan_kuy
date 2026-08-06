import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/bill_history.dart';
import '../../domain/usecases/clear_bill_history_usecase.dart';
import '../../domain/usecases/delete_bill_history_usecase.dart';
import '../../domain/usecases/get_bill_history_usecase.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetBillHistoryUseCase _getBillHistoryUseCase;
  final DeleteBillHistoryUseCase _deleteBillHistoryUseCase;
  final ClearBillHistoryUseCase _clearBillHistoryUseCase;

  HistoryBloc({
    required GetBillHistoryUseCase getBillHistoryUseCase,
    required DeleteBillHistoryUseCase deleteBillHistoryUseCase,
    required ClearBillHistoryUseCase clearBillHistoryUseCase,
  }) : _getBillHistoryUseCase = getBillHistoryUseCase,
       _deleteBillHistoryUseCase = deleteBillHistoryUseCase,
       _clearBillHistoryUseCase = clearBillHistoryUseCase,
       super(const HistoryState()) {
    on<LoadHistory>(_onLoadHistory);
    on<DeleteHistoryEntry>(_onDeleteHistoryEntry);
    on<ClearHistory>(_onClearHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    final result = await _getBillHistoryUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HistoryStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (entries) =>
          emit(state.copyWith(status: HistoryStatus.loaded, entries: entries)),
    );
  }

  Future<void> _onDeleteHistoryEntry(
    DeleteHistoryEntry event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _deleteBillHistoryUseCase(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HistoryStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: HistoryStatus.loaded,
          entries: state.entries.where((e) => e.id != event.id).toList(),
        ),
      ),
    );
  }

  Future<void> _onClearHistory(
    ClearHistory event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _clearBillHistoryUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HistoryStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) =>
          emit(state.copyWith(status: HistoryStatus.loaded, entries: const [])),
    );
  }
}
