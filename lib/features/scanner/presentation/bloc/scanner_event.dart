part of 'scanner_bloc.dart';

sealed class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class PickAndScanImage extends ScannerEvent {

  final bool fromCamera;

  const PickAndScanImage({this.fromCamera = false});
}

class ScanReceiptImage extends ScannerEvent {
  final String imagePath;

  const ScanReceiptImage({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}
