import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/parsed_receipt.dart';
import '../../domain/usecases/extract_receipt_data_usecase.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ExtractReceiptDataUseCase _extractReceiptDataUseCase;
  final ImagePicker _imagePicker;

  ScannerBloc({required ExtractReceiptDataUseCase extractReceiptDataUseCase, ImagePicker? imagePicker})
    : _extractReceiptDataUseCase = extractReceiptDataUseCase,
      _imagePicker = imagePicker ?? ImagePicker(),
      super(const ScannerState()) {
    on<PickAndScanImage>(_onPickAndScanImage);
    on<ScanReceiptImage>(_onScanReceiptImage);
  }

  Future<void> _onPickAndScanImage(PickAndScanImage event, Emitter<ScannerState> emit) async {
    emit(state.copyWith(status: ScannerStatus.loading, clearError: true, clearParsed: true));

    try {
      final XFile? pickedFile;
      if (event.fromCamera) {
        pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
      } else {
        pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      }

      if (pickedFile == null) {

        emit(state.copyWith(status: ScannerStatus.initial));
        return;
      }

      add(ScanReceiptImage(imagePath: pickedFile.path));
    } catch (e) {
      emit(state.copyWith(status: ScannerStatus.error, errorMessage: 'Failed to pick image: $e'));
    }
  }

  Future<void> _onScanReceiptImage(ScanReceiptImage event, Emitter<ScannerState> emit) async {
    emit(state.copyWith(status: ScannerStatus.loading, clearError: true, clearParsed: true));

    final result = await _extractReceiptDataUseCase(event.imagePath);

    result.fold(
      (failure) => emit(state.copyWith(status: ScannerStatus.error, errorMessage: failure.message)),
      (parsedReceipt) => emit(state.copyWith(status: ScannerStatus.success, parsedReceipt: parsedReceipt)),
    );
  }
}
