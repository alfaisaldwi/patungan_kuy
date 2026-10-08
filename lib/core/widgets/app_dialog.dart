import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppDialogTone { primary, danger }

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppTheme.brandNavy.withAlpha(110),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) => builder(dialogContext),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  IconData? icon,
  AppDialogTone tone = AppDialogTone.primary,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      onCancel: () => Navigator.pop(dialogContext, false),
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  return result ?? false;
}

class AppDialog extends StatelessWidget {
  final IconData? icon;
  final AppDialogTone tone;
  final String title;
  final String? message;
  final Widget? content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const AppDialog({
    super.key,
    this.icon,
    this.tone = AppDialogTone.primary,
    required this.title,
    this.message,
    this.content,
    this.cancelLabel = 'Batal',
    required this.confirmLabel,
    this.onCancel,
    this.onConfirm,
  });

  bool get _danger => tone == AppDialogTone.danger;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _danger
                          ? AppTheme.errorLight
                          : AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: _danger ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.heading3.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(fontSize: 14, height: 1.5),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 20),
                Flexible(child: SingleChildScrollView(child: content)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel,
                      onPressed:
                          onCancel ?? () => Navigator.of(context).maybePop(),
                      background: AppTheme.background,
                      foreground: AppTheme.textPrimary,
                      bordered: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      onPressed: onConfirm,
                      background: _danger ? AppTheme.error : AppTheme.cta,
                      foreground: _danger ? Colors.white : AppTheme.onCta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool bordered;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: bordered
                ? BorderSide(color: AppTheme.border)
                : BorderSide.none,
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
