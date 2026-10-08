import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppToastTone { success, error, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    AppToastTone tone = AppToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                _dismiss();
                onAction();
              },
        onDismissed: () {
          if (_current == entry) _dismiss();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, () {
      if (_current == entry) _dismiss();
    });
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current?.dispose();
    _current = null;
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final AppToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _ToastView({
    required this.message,
    required this.tone,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (IconData, Color) get _style => switch (widget.tone) {
    AppToastTone.success => (Icons.check_circle_rounded, AppTheme.success),
    AppToastTone.error => (Icons.error_rounded, AppTheme.error),
    AppToastTone.info => (Icons.info_rounded, AppTheme.brandYellow),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(curved),
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismissed(),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.brandNavy,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandNavy.withAlpha(50),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null)
                        TextButton(
                          onPressed: widget.onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.brandYellow,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(widget.actionLabel!),
                        )
                      else
                        const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
