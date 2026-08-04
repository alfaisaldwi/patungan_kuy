import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../history/domain/entities/bill_history.dart';
import '../../../history/domain/usecases/save_bill_history_usecase.dart';
import '../../domain/entities/bill_result.dart';
import '../../domain/entities/person_order.dart';
import '../../domain/usecases/calculate_bill_usecase.dart';

part 'calculator_event.dart';
part 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final CalculateBillUseCase _calculateBillUseCase;
  final SaveBillHistoryUseCase _saveBillHistoryUseCase;

  /// Signature of the last auto-saved calculation, used to avoid writing
  /// duplicate history entries when the same bill is recalculated.
  String? _lastSavedSignature;

  CalculatorBloc({
    required CalculateBillUseCase calculateBillUseCase,
    required SaveBillHistoryUseCase saveBillHistoryUseCase,
  })  : _calculateBillUseCase = calculateBillUseCase,
        _saveBillHistoryUseCase = saveBillHistoryUseCase,
        super(const CalculatorState()) {

    on<AddPersonOrder>(_onAddPersonOrder);
    on<UpdatePersonOrder>(_onUpdatePersonOrder);
    on<RemovePersonOrder>(_onRemovePersonOrder);
    on<UpdateFeesAndDiscount>(_onUpdateFeesAndDiscount);
    on<CalculateBillEvent>(_onCalculateBill);
    on<RestoreFromHistory>(_onRestoreFromHistory);
  }

  void _onAddPersonOrder(AddPersonOrder event, Emitter<CalculatorState> emit) {
    final newOrder = PersonOrder(id: _generateId(), name: event.name, items: event.items);
    emit(
      state.copyWith(
        orders: [...state.orders, newOrder],
        status: CalculatorStatus.initial,
        clearResult: true,
        clearError: true,
      ),
    );
  }

  void _onUpdatePersonOrder(UpdatePersonOrder event, Emitter<CalculatorState> emit) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == event.id) {
        return PersonOrder(id: order.id, name: event.name, items: event.items);
      }
      return order;
    }).toList();
    emit(state.copyWith(orders: updatedOrders, status: CalculatorStatus.initial, clearResult: true, clearError: true));
  }

  void _onRemovePersonOrder(RemovePersonOrder event, Emitter<CalculatorState> emit) {
    final filteredOrders = state.orders.where((order) => order.id != event.id).toList();
    emit(state.copyWith(orders: filteredOrders, status: CalculatorStatus.initial, clearResult: true, clearError: true));
  }

  void _onUpdateFeesAndDiscount(UpdateFeesAndDiscount event, Emitter<CalculatorState> emit) {
    emit(
      state.copyWith(
        taxFee: event.taxFee,
        deliveryFee: event.deliveryFee,
        discountAmount: event.discountAmount,
        isDiscountPercentage: event.isDiscountPercentage,
        status: CalculatorStatus.initial,
        clearResult: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onCalculateBill(CalculateBillEvent event, Emitter<CalculatorState> emit) async {
    final params = CalculateBillParams(
      orders: state.orders,
      taxFee: state.taxFee,
      deliveryFee: state.deliveryFee,
      discountAmount: state.discountAmount,
      isDiscountPercentage: state.isDiscountPercentage,
    );

    final result = _calculateBillUseCase(params);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: CalculatorStatus.error, errorMessage: failure.message, clearResult: true)),
      (billResult) => emit(state.copyWith(result: billResult, status: CalculatorStatus.calculated, clearError: true)),
    );

    final billResult = result.toOption().toNullable();
    if (billResult != null) {
      await _autoSaveHistory(billResult);
    }
  }

  void _onRestoreFromHistory(RestoreFromHistory event, Emitter<CalculatorState> emit) {
    final entry = event.entry;
    // Mark as already saved so recalculating the restored bill unchanged
    // does not create a duplicate history entry.
    _lastSavedSignature = _signature(entry.orders, entry.taxFee, entry.deliveryFee, entry.discountAmount,
        entry.isDiscountPercentage);
    emit(
      CalculatorState(
        orders: entry.orders,
        taxFee: entry.taxFee,
        deliveryFee: entry.deliveryFee,
        discountAmount: entry.discountAmount,
        isDiscountPercentage: entry.isDiscountPercentage,
        result: entry.result,
        status: CalculatorStatus.calculated,
      ),
    );
  }

  Future<void> _autoSaveHistory(BillResult billResult) async {
    final signature =
        _signature(state.orders, state.taxFee, state.deliveryFee, state.discountAmount, state.isDiscountPercentage);
    if (signature == _lastSavedSignature) return;

    final now = DateTime.now();
    final saved = await _saveBillHistoryUseCase(
      BillHistory(
        id: 'bill_${now.microsecondsSinceEpoch}',
        createdAt: now,
        orders: state.orders,
        taxFee: state.taxFee,
        deliveryFee: state.deliveryFee,
        discountAmount: state.discountAmount,
        isDiscountPercentage: state.isDiscountPercentage,
        result: billResult,
      ),
    );
    // History is best-effort: a failed save never disrupts the calculation UX.
    saved.fold((_) {}, (_) => _lastSavedSignature = signature);
  }

  String _signature(List<PersonOrder> orders, double taxFee, double deliveryFee, double discountAmount,
      bool isDiscountPercentage) {
    final ordersPart = orders
        .map((o) => '${o.name}:${o.items.map((i) => '${i.name}=${i.price}').join(',')}')
        .join('|');
    return '$ordersPart#$taxFee#$deliveryFee#$discountAmount#$isDiscountPercentage';
  }

  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}_${state.orders.length}';
}
