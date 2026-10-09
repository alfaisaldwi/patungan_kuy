import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/core/theme/app_theme.dart';

String _type(TextInputFormatter f, String old, String typed) => f
    .formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: typed.length),
      ),
    )
    .text;

void main() {
  test('nominal Rp tampil dengan pemisah ribuan', () {
    expect(AppTheme.formatRupiah(43260.0), 'Rp 43.260');
    expect(_type(AppTheme.rupiahFormatter, '', '43000'), 'Rp 43.000');
  });

  group('persen', () {
    test('desimal pakai koma, titik diubah jadi koma', () {
      expect(_type(AppTheme.percentFormatter, '12', '12.5'), '12,5');
      expect(AppTheme.parsePercent('12,5'), 12.5);
    });

    test('maks 2 angka di belakang koma dan maks 100', () {
      expect(_type(AppTheme.percentFormatter, '12,55', '12,555'), '12,55');
      expect(_type(AppTheme.percentFormatter, '10', '101'), '10');
      expect(_type(AppTheme.percentFormatter, '', 'a'), '');
    });

    test('nilai dari state ditampilkan rapi', () {
      expect(AppTheme.formatPercent(10.0), '10');
      expect(AppTheme.formatPercent(12.5), '12,5');
    });
  });
}
