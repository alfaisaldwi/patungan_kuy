import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onReveal;

  final VoidCallback onFinished;

  const SplashPage({
    super.key,
    required this.onReveal,
    required this.onFinished,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _navy = Color(0xFF1F2A44);

  static const _logoAsset = 'assets/branding/logo_horizontal_light.png';
  static const _logoW = 250.0;
  static const _logoH = _logoW * 600 / 1920;

  static const _markFrac = 170 / 640;

  static const _publisherAsset = 'assets/images/elumi.png';
  static const _publisherSize = 32.0;

  static const _holdBeforeReveal = Duration(milliseconds: 2200);
  static const _fadeDelay = Duration(milliseconds: 100);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final Animation<double> _markScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
  );
  late final Animation<double> _markTurn = Tween<double>(begin: -0.06, end: 0)
      .animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
  );
  late final Animation<double> _publisherFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );
  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _timers.add(
      Timer(_holdBeforeReveal, () {
        if (!mounted) return;
        widget.onReveal();
        _timers.add(
          Timer(_fadeDelay, () {
            if (!mounted) return;
            _exit.forward().whenComplete(() {
              if (mounted) widget.onFinished();
            });
          }),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _intro.dispose();
    _dots.dispose();
    _exit.dispose();
    super.dispose();
  }

  Widget _logoPart({required double from, required double width}) {
    return SizedBox(
      width: _logoW * width,
      height: _logoH,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: _logoW,
          maxWidth: _logoW,
          minHeight: _logoH,
          maxHeight: _logoH,
          child: Transform.translate(
            offset: Offset(-from * _logoW, 0),
            child: Image.asset(
              _logoAsset,
              width: _logoW,
              height: _logoH,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _intro,
          builder: (context, child) => Transform.rotate(
            angle: _markTurn.value * 2 * math.pi,
            child: Transform.scale(
              scale: _markScale.value.clamp(0.0, 1.4),
              child: child,
            ),
          ),
          child: _logoPart(from: 0, width: _markFrac),
        ),
        AnimatedBuilder(
          animation: _intro,
          builder: (context, child) => Opacity(
            opacity: _textFade.value,
            child: Transform.translate(
              offset: Offset(-24 * (1 - _textFade.value), 0),
              child: child,
            ),
          ),
          child: _logoPart(from: _markFrac, width: 1 - _markFrac),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: Listenable.merge([_dots, _dotsFade]),
      builder: (context, _) {
        return Opacity(
          opacity: _dotsFade.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _navy.withValues(
                      alpha:
                          0.25 +
                          0.75 *
                              (0.5 +
                                  0.5 *
                                      math.sin(
                                        2 * math.pi * (_dots.value - i * 0.18),
                                      )),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublisher() {
    return FadeTransition(
      opacity: _publisherFade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  _publisherAsset,
                  width: _publisherSize,
                  height: _publisherSize,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Elumi',
                style: GoogleFonts.arimo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: FadeTransition(
        opacity: ReverseAnimation(_exit),
        child: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            child: Stack(
              children: [
                Center(child: _buildLogo()),
                Align(alignment: const Alignment(0, 0.62), child: _buildDots()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _buildPublisher(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
