import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/calculator/data/repositories/calculator_repository_impl.dart';
import 'features/calculator/domain/repositories/calculator_repository.dart';
import 'features/calculator/domain/usecases/calculate_bill_usecase.dart';
import 'features/calculator/presentation/bloc/calculator_bloc.dart';
import 'features/history/data/datasources/bill_history_datasource.dart';
import 'features/history/data/repositories/bill_history_repository_impl.dart';
import 'features/history/domain/repositories/bill_history_repository.dart';
import 'features/history/domain/usecases/clear_bill_history_usecase.dart';
import 'features/history/domain/usecases/delete_bill_history_usecase.dart';
import 'features/history/domain/usecases/get_bill_history_usecase.dart';
import 'features/history/domain/usecases/save_bill_history_usecase.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/scanner/data/datasources/receipt_scanner_datasource.dart';
import 'features/scanner/data/repositories/receipt_scanner_repository_impl.dart';
import 'features/scanner/domain/repositories/receipt_scanner_repository.dart';
import 'features/scanner/domain/usecases/extract_receipt_data_usecase.dart';
import 'features/scanner/presentation/bloc/scanner_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final historyBox = await _openHistoryBox();

  sl.registerLazySingleton<CalculatorRepository>(
    () => CalculatorRepositoryImpl(),
  );

  sl.registerLazySingleton<ReceiptScannerDataSource>(
    () => ReceiptScannerDataSource(),
  );
  sl.registerLazySingleton<ReceiptScannerRepository>(
    () => ReceiptScannerRepositoryImpl(sl<ReceiptScannerDataSource>()),
  );

  sl.registerLazySingleton<BillHistoryDataSource>(
    () => BillHistoryDataSource(historyBox),
  );
  sl.registerLazySingleton<BillHistoryRepository>(
    () => BillHistoryRepositoryImpl(sl<BillHistoryDataSource>()),
  );

  sl.registerLazySingleton<CalculateBillUseCase>(
    () => CalculateBillUseCase(sl<CalculatorRepository>()),
  );
  sl.registerLazySingleton<ExtractReceiptDataUseCase>(
    () => ExtractReceiptDataUseCase(sl<ReceiptScannerRepository>()),
  );
  sl.registerLazySingleton<GetBillHistoryUseCase>(
    () => GetBillHistoryUseCase(sl<BillHistoryRepository>()),
  );
  sl.registerLazySingleton<SaveBillHistoryUseCase>(
    () => SaveBillHistoryUseCase(sl<BillHistoryRepository>()),
  );
  sl.registerLazySingleton<DeleteBillHistoryUseCase>(
    () => DeleteBillHistoryUseCase(sl<BillHistoryRepository>()),
  );
  sl.registerLazySingleton<ClearBillHistoryUseCase>(
    () => ClearBillHistoryUseCase(sl<BillHistoryRepository>()),
  );

  // App-lifetime singletons so bloc state survives full re-inflation of the
  // widget tree (e.g. when the theme mode is toggled).
  sl.registerLazySingleton<CalculatorBloc>(
    () => CalculatorBloc(
      calculateBillUseCase: sl<CalculateBillUseCase>(),
      saveBillHistoryUseCase: sl<SaveBillHistoryUseCase>(),
    ),
  );
  sl.registerLazySingleton<ScannerBloc>(
    () =>
        ScannerBloc(extractReceiptDataUseCase: sl<ExtractReceiptDataUseCase>()),
  );

  // Page-scoped: HistoryPage creates and closes its own instance.
  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      getBillHistoryUseCase: sl<GetBillHistoryUseCase>(),
      deleteBillHistoryUseCase: sl<DeleteBillHistoryUseCase>(),
      clearBillHistoryUseCase: sl<ClearBillHistoryUseCase>(),
    ),
  );
}

Future<Box<String>> _openHistoryBox() async {
  try {
    await Hive.initFlutter();
  } catch (_) {
    // path_provider is unavailable in unit/widget tests; fall back to a
    // temporary directory so Hive still works.
    Hive.init(Directory.systemTemp.createTempSync('patungan_kuy_hive').path);
  }
  return Hive.openBox<String>(BillHistoryDataSource.boxName);
}
