import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/bill_history.dart';
import '../models/bill_history_model.dart';

class BillHistoryDataSource {
  static const String boxName = 'bill_history';

  /// Oldest entries are evicted once the box grows past this size.
  static const int maxEntries = 100;

  final Box<String> _box;

  BillHistoryDataSource(this._box);

  List<BillHistory> getAll() {
    final entries = _box.values
        .map((raw) => BillHistoryModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(BillHistory entry) async {
    await _box.put(entry.id, jsonEncode(BillHistoryModel.toJson(entry)));
    await _evictOldest();
  }

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  Future<void> _evictOldest() async {
    if (_box.length <= maxEntries) return;
    final entries = getAll();
    final excess = entries.length - maxEntries;
    final oldestIds = entries.reversed.take(excess).map((e) => e.id).toList();
    await _box.deleteAll(oldestIds);
  }
}
