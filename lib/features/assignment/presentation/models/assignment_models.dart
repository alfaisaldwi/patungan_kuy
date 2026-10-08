import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;

  const Person({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class ItemQuantity {
  ItemQuantity._();

  static final _leading = RegExp(r'^\s*(\d{1,2})\s*[xX×]\s*(?=\S)');
  static final _leadingX = RegExp(r'^\s*[xX×]\s*(\d{1,2})\s+(?=\S)');
  static final _trailing = RegExp(r'\s+[xX×]\s*(\d{1,2})\s*$');

  static int detect(String name) {
    for (final re in [_leading, _leadingX, _trailing]) {
      final match = re.firstMatch(name);
      if (match != null) return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  static String baseName(String name) {
    var result = name;
    for (final re in [_leading, _leadingX, _trailing]) {
      result = result.replaceFirst(re, '');
    }
    result = result.trim();
    return result.isEmpty ? name.trim() : result;
  }
}

class AssignableItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final List<String> assignedPersonIds;

  const AssignableItem({
    required this.id,
    required this.name,
    required this.price,
    this.assignedPersonIds = const [],
  });

  bool isAssignedTo(String personId) => assignedPersonIds.contains(personId);

  bool get isUnassigned => assignedPersonIds.isEmpty;

  bool get isShared => assignedPersonIds.length > 1;

  double get sharePrice =>
      assignedPersonIds.isEmpty ? price : price / assignedPersonIds.length;

  AssignableItem copyWith({
    String? name,
    double? price,
    List<String>? assignedPersonIds,
  }) {
    return AssignableItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      assignedPersonIds: assignedPersonIds ?? this.assignedPersonIds,
    );
  }

  @override
  List<Object?> get props => [id, name, price, assignedPersonIds];
}
