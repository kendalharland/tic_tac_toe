import 'dart:async';
import 'package:tic_tac_toe.database/database.dart';

class TestingDatabase<K, V> implements Database<K, V> {
  Map<K, V> entries;

  TestingDatabase.filled(this.entries);

  TestingDatabase() : entries = <K,V>{};

  @override
  bool containsKey(K key) => entries.containsKey(key);

  @override
  Future<V> get(K key) async => entries[key];

  @override
  Future<V> insert(K key, V value) async => (entries[key] = value);

  @override
  Future<V> remove(K key) async => entries.remove(key);

  @override
  Future<V> update(K key, V value) => insert(key, value);

  @override
  Future<Iterable<V>> where(bool filter(K key, V value)) async {
    var results = <V>[];

    entries.forEach((K key, V value) {
      if (filter(key, value)) {
        results.add(value);
      }
    });
    return results;
  }
}
