import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../theme/app_theme.dart';

/// Tur fitur untuk pengguna baru. Status "sudah pernah lihat" tiap tur
/// disimpan di SharedPreferences (offline), jadi tur hanya muncul sekali.
class ShowcaseTour {
  ShowcaseTour._();

  // ── Tur beranda ──────────────────────────────────────────────────────────
  static const String _homePref = 'has_seen_showcase';

  static final scanKey = GlobalKey(debugLabel: 'tour_scan');
  static final manualKey = GlobalKey(debugLabel: 'tour_manual');
  static final themeKey = GlobalKey(debugLabel: 'tour_theme');
  static final historyKey = GlobalKey(debugLabel: 'tour_history');

  static List<GlobalKey> get steps => [
    scanKey,
    manualKey,
    themeKey,
    historyKey,
  ];

  // ── Tur halaman bagi-bagi item ───────────────────────────────────────────
  static const String assignmentScope = 'assignment';
  static const String _assignmentPref = 'has_seen_assignment_showcase';

  static final assignNameKey = GlobalKey(debugLabel: 'tour_assign_name');
  static final assignEditKey = GlobalKey(debugLabel: 'tour_assign_edit');
  static final assignItemKey = GlobalKey(debugLabel: 'tour_assign_item');
  static final assignFinishKey = GlobalKey(debugLabel: 'tour_assign_finish');

  static List<GlobalKey> get assignmentSteps => [
    assignNameKey,
    assignEditKey,
    assignItemKey,
    assignFinishKey,
  ];

  /// Daftarkan sekali di awal aplikasi, sebelum widget [TourTarget] dibangun.
  static void register() {
    ShowcaseView.register(
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      onFinish: () => _markSeen(_homePref),
      onDismiss: (_) => _markSeen(_homePref),
      globalTooltipActionConfig: _actionConfig,
      globalTooltipActions: _actions(last: historyKey),
    );
  }

  /// Dipanggil oleh halaman bagi-bagi item; kembalikan view-nya agar bisa
  /// di-`unregister` saat halaman ditutup.
  static ShowcaseView registerAssignment() {
    return ShowcaseView.register(
      scope: assignmentScope,
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      onFinish: () => _markSeen(_assignmentPref),
      onDismiss: (_) => _markSeen(_assignmentPref),
      globalTooltipActionConfig: _actionConfig,
      globalTooltipActions: _actions(last: assignFinishKey),
    );
  }

  static const _actionConfig = TooltipActionConfig(
    position: TooltipActionPosition.inside,
    alignment: MainAxisAlignment.spaceBetween,
    actionGap: 8,
    gapBetweenContentAndAction: 8,
  );

  /// "Lewati" + "Lanjut" di semua langkah, "Selesai" hanya di langkah [last].
  static List<TooltipActionButton> _actions({required GlobalKey last}) {
    const onPrimary = Colors.white;
    final primary = AppTheme.primary;
    const pill = EdgeInsets.symmetric(horizontal: 14, vertical: 5);
    const pillText = TextStyle(
      color: onPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return [
      TooltipActionButton(
        type: TooltipDefaultActionType.skip,
        name: 'Lewati',
        textStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        hideActionWidgetForShowcase: [last],
      ),
      TooltipActionButton(
        type: TooltipDefaultActionType.next,
        name: 'Lanjut',
        textStyle: pillText,
        backgroundColor: primary,
        padding: pill,
        hideActionWidgetForShowcase: [last],
      ),
      TooltipActionButton(
        type: TooltipDefaultActionType.next,
        name: 'Selesai',
        textStyle: pillText,
        backgroundColor: primary,
        padding: pill,
        hideActionWidgetForShowcase: [
          for (final k in (last == historyKey ? steps : assignmentSteps))
            if (k != last) k,
        ],
      ),
    ];
  }

  /// Jika gagal membaca, anggap sudah pernah lihat supaya tidak mengganggu.
  static Future<bool> _hasSeen(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _markSeen(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  /// Mulai tur beranda kalau belum pernah ditampilkan. [delay] memberi waktu
  /// agar splash dan transisi halaman selesai dulu.
  static Future<void> startIfFirstTime({
    required bool Function() canStart,
    Duration delay = const Duration(milliseconds: 900),
  }) => _startIfFirstTime(
    pref: _homePref,
    view: ShowcaseView.get,
    steps: steps,
    canStart: canStart,
    delay: delay,
  );

  static Future<void> startAssignmentIfFirstTime({
    required bool Function() canStart,
    Duration delay = const Duration(milliseconds: 500),
  }) => _startIfFirstTime(
    pref: _assignmentPref,
    view: () => ShowcaseView.getNamed(assignmentScope),
    steps: assignmentSteps,
    canStart: canStart,
    delay: delay,
  );

  static Future<void> _startIfFirstTime({
    required String pref,
    required ShowcaseView Function() view,
    required List<GlobalKey> steps,
    required bool Function() canStart,
    required Duration delay,
  }) async {
    if (await _hasSeen(pref)) return;
    await Future<void>.delayed(delay);
    if (!canStart()) return;
    final v = view();
    if (v.isShowcaseRunning) return;
    v.startShowCase(steps);
  }
}

/// Pembungkus [Showcase] dengan gaya PatunganKuy.
class TourTarget extends StatelessWidget {
  final GlobalKey tourKey;
  final String title;
  final String description;
  final double radius;
  final String? scope;
  final Widget child;

  const TourTarget({
    super.key,
    required this.tourKey,
    required this.title,
    required this.description,
    required this.child,
    this.radius = AppTheme.radiusLg,
    this.scope,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: tourKey,
      scope: scope,
      title: title,
      description: description,
      targetBorderRadius: BorderRadius.circular(radius),
      targetPadding: const EdgeInsets.all(2),
      overlayColor: Colors.black,
      overlayOpacity: 0.55,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      tooltipBackgroundColor: AppTheme.surface,
      textColor: AppTheme.textPrimary,
      tooltipBorderRadius: BorderRadius.circular(AppTheme.radiusMd),
      tooltipPadding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      targetTooltipGap: 8,
      titleTextStyle: AppTheme.label.copyWith(fontSize: 14),
      descTextStyle: AppTheme.bodySmall.copyWith(height: 1.35, fontSize: 12.5),
      child: child,
    );
  }
}
