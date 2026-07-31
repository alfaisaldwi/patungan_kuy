import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/bill_result.dart';
import '../../domain/entities/person_order.dart';
import '../../domain/usecases/calculate_bill_usecase.dart';

part 'calculator_event.dart';
part 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final CalculateBillUseCase _calculateBillUseCase;

  CalculatorBloc({required CalculateBillUseCase calculateBillUseCase})
    : _calculateBillUseCase = calculateBillUseCase,
      super(const CalculatorState()) {

    on<AddPersonOrder>(_onAddPersonOrder);
    on<UpdatePersonOrder>(_onUpdatePersonOrder);
    on<RemovePersonOrder>(_onRemovePersonOrder);
    on<UpdateFeesAndDiscount>(_onUpdateFeesAndDiscount);
    on<CalculateBillEvent>(_onCalculateBill);
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

  void _onCalculateBill(CalculateBillEvent event, Emitter<CalculatorState> emit) {
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
  }

  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}_${state.orders.length}';
}
