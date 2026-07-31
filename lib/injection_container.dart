import 'package:get_it/get_it.dart';

import 'features/calculator/data/repositories/calculator_repository_impl.dart';
import 'features/calculator/domain/repositories/calculator_repository.dart';
import 'features/calculator/domain/usecases/calculate_bill_usecase.dart';
import 'features/calculator/presentation/bloc/calculator_bloc.dart';
import 'features/scanner/data/datasources/receipt_scanner_datasource.dart';
import 'features/scanner/data/repositories/receipt_scanner_repository_impl.dart';
import 'features/scanner/domain/repositories/receipt_scanner_repository.dart';
import 'features/scanner/domain/usecases/extract_receipt_data_usecase.dart';
import 'features/scanner/presentation/bloc/scanner_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {

  sl.registerLazySingleton<CalculatorRepository>(() => CalculatorRepositoryImpl());

  sl.registerLazySingleton<ReceiptScannerDataSource>(() => ReceiptScannerDataSource());
  sl.registerLazySingleton<ReceiptScannerRepository>(
    () => ReceiptScannerRepositoryImpl(sl<ReceiptScannerDataSource>()),
  );

  sl.registerLazySingleton<CalculateBillUseCase>(() => CalculateBillUseCase(sl<CalculatorRepository>()));
  sl.registerLazySingleton<ExtractReceiptDataUseCase>(() => ExtractReceiptDataUseCase(sl<ReceiptScannerRepository>()));

  sl.registerFactory<CalculatorBloc>(() => CalculatorBloc(calculateBillUseCase: sl<CalculateBillUseCase>()));
  sl.registerFactory<ScannerBloc>(() => ScannerBloc(extractReceiptDataUseCase: sl<ExtractReceiptDataUseCase>()));
}
