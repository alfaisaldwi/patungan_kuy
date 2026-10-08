import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _exampleImages = [
  'assets/images/example/example_1.jpg',
  'assets/images/example/example_2.jpg',
  'assets/images/example/example_3.jpg',
  'assets/images/example/example_4.jpg',
  'assets/images/example/example_5.png',
];

void showReceiptExamples(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
    ),
    builder: (_) => const _ReceiptExamplesSheet(),
  );
}

class _ReceiptExamplesSheet extends StatefulWidget {
  const _ReceiptExamplesSheet();

  @override
  State<_ReceiptExamplesSheet> createState() => _ReceiptExamplesSheetState();
}

class _ReceiptExamplesSheetState extends State<_ReceiptExamplesSheet> {
  final _controller = PageController(viewportFraction: 0.72);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingCard,
              ),
              child: Column(
                children: [
                  Text('Contoh Struk', style: AppTheme.heading3),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    'Pastikan daftar item, harga, diskon & ongkir kelihatan jelas. '
                    'Tap gambar buat zoom.',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            SizedBox(
              height: height * 0.55,
              child: PageView.builder(
                controller: _controller,
                itemCount: _exampleImages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _openFullscreen(context, i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [AppTheme.shadowSm],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Hero(
                      tag: _exampleImages[i],
                      child: Image.asset(
                        _exampleImages[i],
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_exampleImages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : AppTheme.disabled,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => _FullscreenExample(path: _exampleImages[index]),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _FullscreenExample extends StatefulWidget {
  const _FullscreenExample({required this.path});

  final String path;

  @override
  State<_FullscreenExample> createState() => _FullscreenExampleState();
}

class _FullscreenExampleState extends State<_FullscreenExample>
    with SingleTickerProviderStateMixin {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 800.0;

  final _transform = TransformationController();
  late final _resetController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(() => setState(() => _dragDy = _resetAnimation.value));
  Animation<double> _resetAnimation = const AlwaysStoppedAnimation(0);

  bool _zoomed = false;
  double _dragDy = 0;

  @override
  void dispose() {
    _transform.dispose();
    _resetController.dispose();
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    if (_zoomed || details.pointerCount != 1) return;
    setState(() => _dragDy += details.focalPointDelta.dy);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    if (_zoomed || _dragDy == 0) return;

    final shouldDismiss =
        _dragDy.abs() > _dismissDistance ||
        details.velocity.pixelsPerSecond.dy.abs() > _dismissVelocity;
    if (shouldDismiss) {
      Navigator.pop(context);
      return;
    }

    _resetAnimation = Tween(begin: _dragDy, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragDy.abs() / (_dismissDistance * 2)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1 - progress),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Transform.translate(
                offset: Offset(0, _dragDy),
                child: InteractiveViewer(
                  transformationController: _transform,
                  maxScale: 4,
                  panEnabled: _zoomed,
                  onInteractionUpdate: _onInteractionUpdate,
                  onInteractionEnd: _onInteractionEnd,
                  child: Center(
                    child: Hero(
                      tag: widget.path,
                      child: Image.asset(widget.path),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceSm),
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
                child: Text(
                  'Cubit buat zoom • Geser ke bawah atau tap buat tutup',
                  style: AppTheme.caption.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
