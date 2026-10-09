import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/features/scanner/data/parsers/receipt_text_parser.dart';
import 'package:patungan_kuy/features/scanner/domain/entities/parsed_receipt.dart';

// Each fixture is the text of an example in assets/images/example, written the
// way ReceiptScannerRepositoryImpl._extractLines merges ML Kit output: one
// string per visual row, top to bottom, left to right.

const _parser = ReceiptTextParser();

List<(String, double)> _items(ParsedReceipt r) => [
  for (final o in r.orders)
    for (final i in o.items) (i.name, i.price),
];

double _itemsTotal(ParsedReceipt r) =>
    _items(r).fold(0, (sum, item) => sum + item.$2);

void _expectAmounts(
  ParsedReceipt r, {
  required double? subtotal,
  required double fees,
  required double discount,
}) {
  expect(r.detectedSubtotal, subtotal, reason: 'subtotal');
  expect(r.detectedDeliveryFee, fees, reason: 'biaya');
  expect(r.detectedDiscount, discount, reason: 'diskon');
}

void main() {
  group('ShopeeFood - Rincian Pesananmu', () {
    test('example_1: list belum dibuka penuh, strikethrough diabaikan', () {
      final r = _parser.parse([
        '15:59 65.6 KB/s 76%',
        'Rincian Pesananmu',
        'Rincian Pesanan',
        '1 x Kacang Susu Rp33.750',
        'Rp45.000',
        '1 x Keju Kacang Coklat (sedang) Rp25.000',
        '1 x Kacang Coklat Rp44.000',
        'Rp55.000',
        'Lihat Lebih Banyak',
        'Subtotal Pesanan (4 menu) Rp149.150',
        'Voucher Diskon -Rp62.643',
        'Biaya Pengiriman Rp12.500 Rp1.500',
        'Biaya Layanan Rp3.500',
        'Paid Rp91.507',
        'Sudah termasuk pajak',
        'Informasi Pesanan',
        'Catatan Tambahan Tidak ada',
        'No. Pesanan 3207300458754560130 SALIN',
        'Waktu Pemesanan 8 Agt 2026 00:14',
        'Waktu Pembayaran 8 Agt 2026 00:14',
        'Pembayaran ShopeePay',
        'Nota Pesanan Lihat Nota Pesanan',
        'Pesan lagi',
      ]);

      expect(_items(r), [
        ('Kacang Susu', 33750),
        ('Keju Kacang Coklat (sedang)', 25000),
        ('Kacang Coklat', 44000),
      ]);
      _expectAmounts(r, subtotal: 149150, fees: 5000, discount: 62643);
      expect(149150 + 5000 - 62643, 91507);
    });

    test('example_3: catatan menu & ongkir dicoret jadi Rp0', () {
      final r = _parser.parse([
        'Rincian Pesananmu',
        'Bukti Pengiriman',
        'Rincian Pesanan',
        '1 x Coklat Kacang Susu Rp45.000',
        '1 x Biasa Telor Ayam (2Telor) Rp58.000',
        'Pedas',
        'Subtotal Pesanan (2 menu) Rp103.000',
        'Voucher Diskon -Rp43.260',
        'Biaya Pengiriman Rp8.000 Rp0',
        'Biaya Layanan Rp3.500',
        'Paid Rp63.240',
        'Sudah termasuk pajak',
        'Pembayaran SeaBank Bayar Instan',
      ]);

      expect(_items(r), [
        ('Coklat Kacang Susu', 45000),
        ('Biasa Telor Ayam (2Telor)', 58000),
      ]);
      _expectAmounts(r, subtotal: 103000, fees: 3500, discount: 43260);
      expect(103000 + 3500 - 43260, 63240);
    });

    test('example_5: qty 2 dipecah, varian menu diabaikan', () {
      final r = _parser.parse([
        'Rincian Pesananmu',
        'Rincian Pesanan Ubah',
        '1 x Ice Kopi Susu Keluarga Rp18.500',
        'Regular, Fresh Milk, Normal Sugar, Normal',
        'Ice',
        '2 x Ice Kopi Susu Keluarga Rp37.000',
        'Regular, Fresh Milk, No Sugar, Normal Ice',
        '1 x Ubi Bakar Madu Cilembu Pcs Rp12.000',
        '1 x Ice Americano Rp16.500',
        'Regular, Normal (No Sugar), Less Ice',
        '1 x Pao Coklat Besar Rp10.500',
        '1 x Paket Oden Combo 1 Rp35.000',
        'Laksa',
        '1 x Boneless Crispy Chicken Ala Carte Rp17.000',
        'Lihat Lebih Sedikit',
        'Subtotal Pesanan (8 menu) Rp146.500',
        'Voucher Diskon -Rp10.000',
        'Biaya Pengiriman Rp10.000 Rp6.000',
        'Biaya Layanan Rp4.500',
        'Biaya Pengemasan Rp500',
        'Paid Rp147.500',
        'Sudah termasuk pajak',
      ]);

      expect(_items(r), [
        ('Ice Kopi Susu Keluarga', 18500),
        ('Ice Kopi Susu Keluarga (1)', 18500),
        ('Ice Kopi Susu Keluarga (2)', 18500),
        ('Ubi Bakar Madu Cilembu Pcs', 12000),
        ('Ice Americano', 16500),
        ('Pao Coklat Besar', 10500),
        ('Paket Oden Combo 1', 35000),
        ('Boneless Crispy Chicken Ala Carte', 17000),
      ]);
      expect(_itemsTotal(r), 146500);
      _expectAmounts(r, subtotal: 146500, fees: 11000, discount: 10000);
      expect(146500 + 11000 - 10000, 147500);
    });
  });

  group('ShopeeFood - Nota Pesanan', () {
    test('example_2: semua biaya termasuk Biaya Lain-Lain', () {
      final r = _parser.parse([
        'Nota Pesanan',
        'Rincian Pesanan',
        'ShopeeFood',
        'Nama Pembeli: Alex',
        'Restoran: MARTABAK BANG BHUCEK 2 -',
        'KEMBANGAN UTARA',
        'Waktu Pemesanan: 08/08/2026 00:59',
        'No. Pesanan: 3207300458754560130',
        '1 x Kacang Susu Rp33.750',
        '1 x Keju Kacang Coklat (sedang) Rp25.000',
        '1 x Kacang Coklat Rp44.000',
        '1 x Keju Kacang Coklat Rp46.400',
        'Subtotal Pesanan (4 Menu) Rp149.150',
        'Biaya Pengiriman Rp11.000',
        'Biaya Layanan Rp3.500',
        'Biaya Lain-Lain Rp1.500',
        'Diskon Pengiriman -Rp11.000',
        'Voucher Diskon -Rp62.643',
        'Total Pembayaran Rp91.507',
        'Pembayaran ShopeePay',
        'Biaya-biaya yang ditagihkan oleh Shopee (jika',
        'ada) sudah termasuk PPN',
        'PT Shopee International Indonesia',
        'Trinity Tower 21st Floor Jalan H.R. Rasuna Said Kaveling',
        'C22, Blok IIB RT.000 RW.000, Karet Kuningan, Setiabudi,',
      ]);

      expect(_items(r), [
        ('Kacang Susu', 33750),
        ('Keju Kacang Coklat (sedang)', 25000),
        ('Kacang Coklat', 44000),
        ('Keju Kacang Coklat', 46400),
      ]);
      expect(_itemsTotal(r), 149150);
      _expectAmounts(r, subtotal: 149150, fees: 16000, discount: 73643);
      expect(149150 + 16000 - 73643, 91507);
    });

    test('example_4: catatan "- Pedas" bukan diskon', () {
      final r = _parser.parse([
        'Nota Pesanan',
        'Rincian Pesanan',
        'ShopeeFood',
        'Nama Pembeli: Alfaisal Dwi',
        'Restoran: Martabak Pakem - Kedoya Raya',
        'Waktu Pemesanan: 27/09/2026 19:01',
        'No. Pesanan: 3279164268644352130',
        '1 x Coklat Kacang Susu Rp45.000',
        '1 x Biasa Telor Ayam (2Telor) Rp58.000',
        '- Pedas',
        'Subtotal Pesanan (2 Menu) Rp103.000',
        'Biaya Pengiriman Rp10.000',
        'Biaya Layanan Rp3.500',
        'Diskon Pengiriman -Rp10.000',
        'Voucher Diskon -Rp43.260',
        'Total Pembayaran Rp63.240',
        'Pembayaran SeaBank Bayar Instan',
        'Biaya-biaya yang ditagihkan oleh Shopee (jika',
        'ada) sudah termasuk PPN',
        'NPWP: 0736 6669 0003 1000',
      ]);

      expect(_items(r), [
        ('Coklat Kacang Susu', 45000),
        ('Biasa Telor Ayam (2Telor)', 58000),
      ]);
      _expectAmounts(r, subtotal: 103000, fees: 13500, discount: 53260);
      expect(103000 + 13500 - 53260, 63240);
    });
  });

  group('Qty > 1', () {
    test('harga baris dibagi rata walau harga satuan bukan kelipatan 500', () {
      final r = _parser.parse([
        '2 x Teh Tarik Rp15.800',
        '1 x Roti Bakar Rp20.000',
        'Subtotal Rp35.800',
      ]);

      expect(_items(r), [
        ('Teh Tarik (1)', 7900),
        ('Teh Tarik (2)', 7900),
        ('Roti Bakar', 20000),
      ]);
    });

    test('harga satuan dipakai kalau subtotal cocoknya ke harga satuan', () {
      final r = _parser.parse([
        '2 x Teh Tarik Rp8.000',
        '1 x Roti Bakar Rp20.000',
        'Subtotal Rp36.000',
      ]);

      expect(_items(r), [
        ('Teh Tarik (1)', 8000),
        ('Teh Tarik (2)', 8000),
        ('Roti Bakar', 20000),
      ]);
    });
  });

  // Format perkiraan, belum dicek ke screenshot asli GoFood/GrabFood.
  group('Label biaya umum aplikasi lain', () {
    test('ongkos kirim, biaya pemesanan & kemasan terhitung', () {
      final r = _parser.parse([
        '1x Ayam Geprek Rp20.000',
        '1x Es Teh Rp5.000',
        'Subtotal Rp25.000',
        'Ongkos kirim Rp9.000',
        'Biaya pemesanan Rp3.000',
        'Biaya kemasan Rp2.000',
        'Promo -Rp10.000',
        'Total Rp29.000',
      ]);

      expect(_items(r), [('Ayam Geprek', 20000), ('Es Teh', 5000)]);
      _expectAmounts(r, subtotal: 25000, fees: 14000, discount: 10000);
    });
  });
}
