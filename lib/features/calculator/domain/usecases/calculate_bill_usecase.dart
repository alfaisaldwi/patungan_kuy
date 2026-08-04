import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_result.dart';
import '../entities/calculated_bill.dart';
import '../entities/person_order.dart';
import '../repositories/calculator_repository.dart';

class CalculateBillParams {
  final List<PersonOrder> orders;
  final double taxFee;
  final double deliveryFee;
  final double discountAmount;
  final bool isDiscountPercentage;

  const CalculateBillParams({
    required this.orders,
    required this.taxFee,
    required this.deliveryFee,
    required this.discountAmount,
    required this.isDiscountPercentage,
  });
}

class CalculateBillUseCase {
  final CalculatorRepository repository;

  CalculateBillUseCase(this.repository);

  Either<Failure, BillResult> call(CalculateBillParams params) {

    if (params.orders.isEmpty) {
      return const Left(CalculatorFailure('At least one person order is required.'));
    }

    for (final order in params.orders) {
      if (order.name.trim().isEmpty) {
        return const Left(CalculatorFailure('All person names must be non-empty.'));
      }
      if (order.items.isEmpty) {
        return Left(CalculatorFailure('"${order.name}" must have at least one item.'));
      }
      for (final item in order.items) {
        if (item.price <= 0) {
          return Left(CalculatorFailure('Item price for "${order.name}" must be greater than 0.'));
        }
      }
    }

    if (params.taxFee < 0 || params.deliveryFee < 0) {
      return const Left(CalculatorFailure('Tax and delivery fees cannot be negative.'));
    }

    if (params.discountAmount < 0) {
      return const Left(CalculatorFailure('Discount amount cannot be negative.'));
    }

    final totalBase = params.orders.fold<double>(0, (sum, order) => sum + order.totalPrice);

    final totalFees = params.taxFee + params.deliveryFee;

    final totalDiscount = params.isDiscountPercentage
        ? (params.discountAmount / 100) * totalBase
        : params.discountAmount;

    final calculatedBills = params.orders.map((order) {

      final proportion = totalBase > 0 ? order.totalPrice / totalBase : 0.0;

      final proportionalFee = proportion * totalFees;
      final proportionalDiscount = proportion * totalDiscount;
      final finalPayable = order.totalPrice + proportionalFee - proportionalDiscount;

      return CalculatedBill(
        personId: order.id,
        name: order.name,
        originalPrice: order.totalPrice,
        proportionalFee: proportionalFee,
        proportionalDiscount: proportionalDiscount,
        finalPayable: finalPayable,
      );
    }).toList();

    final grandTotal = calculatedBills.fold<double>(0, (sum, bill) => sum + bill.finalPayable);

    return Right(
      BillResult(
        calculatedBills: calculatedBills,
        totalBase: totalBase,
        totalFees: totalFees,
        totalDiscount: totalDiscount,
        grandTotal: grandTotal,
        calculatedAt: DateTime.now(),
      ),
    );
  }
}
