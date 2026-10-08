import 'package:flutter_test/flutter_test.dart';
import 'package:patungan_kuy/features/assignment/presentation/bloc/assignment_bloc.dart';
import 'package:patungan_kuy/features/assignment/presentation/models/assignment_models.dart';
import 'package:patungan_kuy/features/calculator/domain/entities/person_order.dart';
import 'package:patungan_kuy/features/scanner/domain/entities/parsed_receipt.dart';

const _receipt = ParsedReceipt(
  orders: [
    ExtractedOrder(
      name: 'Pesanan',
      items: [
        OrderItem(name: 'Nasi Goreng', price: 25000),
        OrderItem(name: '3x Es Teh', price: 10000),
        OrderItem(name: 'Kerupuk', price: 2000),
      ],
    ),
  ],
);

Future<ReceiptAssignmentBloc> _loaded() async {
  final bloc = ReceiptAssignmentBloc()
    ..add(const LoadScannedItems(receipt: _receipt));
  await Future<void>.delayed(Duration.zero);
  return bloc;
}

void main() {
  group('ItemQuantity', () {
    test('mendeteksi jumlah porsi dari nama item', () {
      expect(ItemQuantity.detect('2x Es Teh'), 2);
      expect(ItemQuantity.detect('2 x Es Teh'), 2);
      expect(ItemQuantity.detect('x3 Es Teh'), 3);
      expect(ItemQuantity.detect('Es Teh x4'), 4);
      expect(ItemQuantity.detect('Es Teh'), 1);
      expect(ItemQuantity.detect('Nasi 2 Telur'), 1);
    });

    test('membuang penanda jumlah dari nama', () {
      expect(ItemQuantity.baseName('2x Es Teh'), 'Es Teh');
      expect(ItemQuantity.baseName('Es Teh x4'), 'Es Teh');
      expect(ItemQuantity.baseName('Es Teh'), 'Es Teh');
    });
  });

  test('pecah item: urutan, nama, dan total harga terjaga', () async {
    final bloc = await _loaded();
    final target = bloc.state.items[1];

    bloc.add(SplitScannedItem(itemId: target.id, parts: 3));
    await Future<void>.delayed(Duration.zero);

    final names = bloc.state.items.map((i) => i.name).toList();
    expect(names, [
      'Nasi Goreng',
      'Es Teh (1/3)',
      'Es Teh (2/3)',
      'Es Teh (3/3)',
      'Kerupuk',
    ]);
    final parts = bloc.state.items.sublist(1, 4).map((i) => i.price);
    expect(parts.reduce((a, b) => a + b), 10000);
    expect(parts.toList(), [3334, 3333, 3333]);
    await bloc.close();
  });

  test('pecah item mewarisi orang yang sudah dipilih', () async {
    final bloc = await _loaded();
    bloc.add(const AddPerson(name: 'Adam'));
    await Future<void>.delayed(Duration.zero);
    final adam = bloc.state.persons.single;
    final target = bloc.state.items[1];
    bloc
      ..add(ToggleItemAssignment(itemId: target.id, personId: adam.id))
      ..add(SplitScannedItem(itemId: target.id, parts: 2));
    await Future<void>.delayed(Duration.zero);

    expect(
      bloc.state.items.sublist(1, 3).every((i) => i.isAssignedTo(adam.id)),
      isTrue,
    );
    await bloc.close();
  });

  test('urungkan mengembalikan item dan orang seperti semula', () async {
    final bloc = await _loaded();
    bloc.add(const AddPerson(name: 'Adam'));
    await Future<void>.delayed(Duration.zero);
    final snapshot = bloc.state;

    bloc
      ..add(RemovePerson(personId: snapshot.persons.single.id))
      ..add(RemoveScannedItem(itemId: snapshot.items.first.id));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.persons, isEmpty);
    expect(bloc.state.items.length, 2);

    bloc.add(
      RestoreAssignmentSnapshot(
        items: snapshot.items,
        persons: snapshot.persons,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.items, snapshot.items);
    expect(bloc.state.persons, snapshot.persons);
    await bloc.close();
  });
}
