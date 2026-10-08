import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bill_result.dart';
import '../../domain/entities/calculated_bill.dart';
import '../../domain/entities/person_order.dart';

class ReceiptImageView extends StatelessWidget {
  static const String logoDark = 'assets/branding/logo_horizontal.png';
  static const String logoLight = 'assets/branding/logo_horizontal_light.png';

  static const _navy = Color(0xFF1F2A44);
  static const _yellow = Color(0xFFFFD23F);
  static const _yellowSoft = Color(0xFFFFF6D6);
  static const _canvas = Color(0xFFF1F5F9);
  static const _ink = Color(0xFF1F2A44);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _panel = Color(0xFFF8FAFC);
  static const _danger = Color(0xFFDC2626);

  static const _avatarColors = <Color>[
    Color(0xFF2E4A8B),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFFD63B6E),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
  ];

  final BillResult result;
  final List<PersonOrder> orders;
  final double width;

  const ReceiptImageView({
    super.key,
    required this.result,
    required this.orders,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bills = result.calculatedBills;

    return SizedBox(
      width: width,
      child: ColoredBox(
        color: _canvas,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipPath(
            clipper: const _ZigZagBottomClipper(),
            child: ColoredBox(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _summary(),
                        const SizedBox(height: 22),
                        _sectionTitle(bills.length),
                        const SizedBox(height: 10),
                        for (var i = 0; i < bills.length; i++)
                          _personCard(i, bills[i]),
                      ],
                    ),
                  ),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _navy,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                logoDark,
                width: 210,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 6),
              const Text(
                'STRUK PATUNGAN',
                style: TextStyle(
                  color: _yellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(result.calculatedAt),
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
              ),
            ],
          ),
        ),
        Container(height: 5, color: _yellow),
      ],
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Subtotal', AppTheme.formatRupiah(result.totalBase)),
          _row('Total Biaya', AppTheme.formatRupiah(result.totalFees)),
          _row(
            'Total Diskon',
            '- ${AppTheme.formatRupiah(result.totalDiscount)}',
            valueColor: result.totalDiscount > 0 ? _danger : null,
          ),
          const SizedBox(height: 10),
          const _Dashed(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _yellowSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _yellow, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL BAYAR',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatRupiah(result.grandTotal),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(int count) {
    return Row(
      children: [
        const Text(
          'Per Orang',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _yellow,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _personCard(int index, CalculatedBill bill) {
    final matches = orders.where((o) => o.id == bill.personId);
    final items = matches.isNotEmpty
        ? matches.first.items
        : const <OrderItem>[];
    final name = bill.name.trim().isEmpty ? 'Tanpa nama' : bill.name.trim();
    final color = _avatarColors[index % _avatarColors.length];
    final hasFee = bill.proportionalFee.round() != 0;
    final hasDiscount = bill.proportionalDiscount.round() != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  String.fromCharCode(name.runes.first).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppTheme.formatRupiah(bill.finalPayable),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _Dashed(),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name.trim().isEmpty ? 'Item' : item.name.trim(),
                        style: const TextStyle(color: _ink, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppTheme.formatRupiah(item.price),
                      style: const TextStyle(color: _ink, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(
                  'Pesanan',
                  AppTheme.formatRupiah(bill.originalPrice),
                  small: true,
                ),
                if (hasFee)
                  _row(
                    '+ Biaya',
                    AppTheme.formatRupiah(bill.proportionalFee),
                    small: true,
                  ),
                if (hasDiscount)
                  _row(
                    '- Diskon',
                    AppTheme.formatRupiah(bill.proportionalDiscount),
                    small: true,
                    valueColor: _danger,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Dashed(),
          const SizedBox(height: 16),
          const Text(
            'Terima kasih sudah patungan!',
            style: TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(logoLight, width: 120, filterQuality: FilterQuality.high),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool small = false,
    Color? valueColor,
  }) {
    final size = small ? 12.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 2 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _muted, fontSize: size),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _ink,
              fontSize: size,
              fontWeight: small ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]} ${d.year}  $hh:$mm';
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReceiptImageView._line
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZigZagBottomClipper extends CustomClipper<Path> {
  const _ZigZagBottomClipper();

  static const _tooth = 14.0;
  static const _depth = 7.0;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - _depth);
    final teeth = (size.width / _tooth).ceil();
    final w = size.width / teeth;
    for (var i = 0; i < teeth; i++) {
      final xRight = size.width - i * w;
      path
        ..lineTo(xRight - w / 2, size.height)
        ..lineTo(xRight - w, size.height - _depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
