import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String name;
  final double price;

  const OrderItem({this.name = '', required this.price});

  @override
  List<Object?> get props => [name, price];
}

class PersonOrder extends Equatable {
  final String id;
  final String name;
  final List<OrderItem> items;

  const PersonOrder({
    required this.id,
    required this.name,
    required this.items,
  });

  double get totalPrice => items.fold(0, (sum, item) => sum + item.price);

  @override
  List<Object?> get props => [id, name, items];
}
