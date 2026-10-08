import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/calculator_bloc.dart';
import '../utils/receipt_image_generator.dart';
import 'receipt_image_view.dart';
import 'package:gal/gal.dart';
import '../../../../core/widgets/app_toast.dart';

class ResultSummaryBar extends StatelessWidget {
  final VoidCallback onView;
  const ResultSummaryBar({super.key, required this.onView});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final Widget child;
        if (state.status != CalculatorStatus.calculated ||
            state.result == null) {
          child = const SafeArea(
            top: false,
            child: SizedBox(width: double.infinity),
          );
        } else {
          child = Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
              boxShadow: [AppTheme.shadowMd],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingPage,
                  vertical: AppTheme.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Bayar', style: AppTheme.bodySmall),
                          Text(
                            AppTheme.formatRupiah(state.result!.grandTotal),
                            style: AppTheme.price,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Lihat Hasil'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
    );
  }
}

class ResultSheet extends StatefulWidget {
  const ResultSheet({super.key});

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

enum _ActionState { idle, busy, done, failed }

class _ResultSheetState extends State<ResultSheet> {
  final _states = <String, _ActionState>{};
  final _messages = <String, String>{};

  static const _share = 'share';
  static const _save = 'save';
  static const _copy = 'copy';

  _ActionState _stateOf(String key) => _states[key] ?? _ActionState.idle;

  bool get _anyBusy => _states.values.contains(_ActionState.busy);

  void _set(String key, _ActionState value, {String? message}) {
    if (!mounted) return;
    setState(() {
      _states[key] = value;
      if (message != null) _messages[key] = message;
    });
    if (value == _ActionState.done || value == _ActionState.failed) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _states[key] == value) {
          setState(() => _states[key] = _ActionState.idle);
        }
      });
    }
  }

  Future<void> _onShare() async {
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null || _anyBusy) return;
    _set(_share, _ActionState.busy);
    final ok = await ReceiptImageGenerator.share(
      context: context,
      result: state.result!,
      orders: state.orders,
    );
    _set(
      _share,
      ok ? _ActionState.idle : _ActionState.failed,
      message: 'Gagal, coba lagi',
    );
    if (!ok && mounted) {
      AppToast.show(
        context,
        message: 'Gagal membagikan struk. Coba lagi, ya.',
        tone: AppToastTone.error,
      );
    }
  }

  Future<void> _onSave() async {
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null || _anyBusy) return;
    _set(_save, _ActionState.busy);
    final result = await ReceiptImageGenerator.saveToGallery(
      context: context,
      result: state.result!,
      orders: state.orders,
    );
    if (!mounted) return;
    switch (result) {
      case GallerySaveResult.saved:
        _set(_save, _ActionState.done, message: 'Tersimpan');
        AppToast.show(
          context,
          message: 'Gambar struk berhasil diunduh ke galeri.',
          actionLabel: 'Buka',
          onAction: Gal.open,
        );
      case GallerySaveResult.denied:
        _set(_save, _ActionState.failed, message: 'Izin ditolak');
        AppToast.show(
          context,
          message: 'Izin galeri ditolak. Aktifkan lewat pengaturan HP.',
          tone: AppToastTone.error,
        );
      case GallerySaveResult.failed:
        _set(_save, _ActionState.failed, message: 'Gagal simpan');
        AppToast.show(
          context,
          message: 'Gagal menyimpan gambar. Coba lagi, ya.',
          tone: AppToastTone.error,
        );
    }
  }

  Future<void> _onCopy() async {
    final state = context.read<CalculatorBloc>().state;
    if (state.result == null) return;
    await Clipboard.setData(
      ClipboardData(text: ReceiptImageGenerator.summaryText(state.result!)),
    );
    _set(_copy, _ActionState.done, message: 'Tersalin');
    if (!mounted) return;
    AppToast.show(
      context,
      message: 'Ringkasan disalin. Tinggal tempel di chat.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
              child: BlocBuilder<CalculatorBloc, CalculatorState>(
                builder: (context, state) {
                  if (state.status != CalculatorStatus.calculated ||
                      state.result == null) {
                    return const SizedBox.shrink();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) => ReceiptImageView(
                      result: state.result!,
                      orders: state.orders,
                      width: constraints.maxWidth,
                    ),
                  );
                },
              ),
            ),
          ),
          BlocBuilder<CalculatorBloc, CalculatorState>(
            buildWhen: (a, b) => a.status != b.status,
            builder: (context, state) {
              if (state.status != CalculatorStatus.calculated) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.paddingPage,
                    0,
                    AppTheme.paddingPage,
                    AppTheme.spaceLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _anyBusy ? null : _onShare,
                          icon: _icon(
                            _share,
                            Icons.share_rounded,
                            onPrimary: true,
                          ),
                          label: Text(
                            _label(_share, 'Bagikan Struk'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _anyBusy ? null : _onSave,
                              icon: _icon(_save, Icons.download_rounded),
                              label: Text(_label(_save, 'Simpan ke Galeri')),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _onCopy,
                              icon: _icon(_copy, Icons.copy_rounded),
                              label: Text(_label(_copy, 'Salin Teks')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _label(String key, String idle) => switch (_stateOf(key)) {
    _ActionState.idle => idle,
    _ActionState.busy => 'Bentar ya...',
    _ActionState.done || _ActionState.failed => _messages[key] ?? idle,
  };

  Widget _icon(String key, IconData idle, {bool onPrimary = false}) {
    return switch (_stateOf(key)) {
      _ActionState.busy => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: onPrimary ? AppTheme.onCta : AppTheme.primary,
        ),
      ),
      _ActionState.done => const Icon(
        Icons.check_rounded,
        size: 18,
        color: AppTheme.success,
      ),
      _ActionState.failed => const Icon(
        Icons.error_outline_rounded,
        size: 18,
        color: AppTheme.error,
      ),
      _ActionState.idle => Icon(idle, size: 18),
    };
  }
}
