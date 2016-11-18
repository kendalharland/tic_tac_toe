import 'dart:async';
import 'dart:io';
import 'package:tic_tac_toe.database/serializer.dart';

/// A very naive key-value store.
abstract class Database<K, V> {
  /// The keys in this [Database].
  Set<K> get keys;

  /// Associates [value] with [key].
  Future<V> insert(K key, V value);

  /// Associates [value] with [key].
  ///
  /// If a value already exists for [key] an Exception is thrown.
  Future<V> update(K key, V value);

  /// Returns the value associated with [key] or null if non exists.
  Future<V> get(K key);

  /// Remove the value associated with [key] if one exists.
  Future<V> remove(K key);

  /// Returns all records in the database that pass [filter].
  Future<Iterable<V>> where(bool filter(K key, V value));
}

/// A simple database that holds all data in-memory.
///
/// The contents can be written to disk via [saveOnDisk].
class MemoryDatabase<K, V> implements Database<K, V> {
  final File _file;
  final Serializer<K> _keySerializer;
  final Serializer<V> _valueSerializer;
  final String _kvDelim = '«';
  final Map<K, V> _records = <K, V>{};

  /// Creates an [MemoryDatabase].
  MemoryDatabase(this._file, this._keySerializer, this._valueSerializer) {
    if(!_file.existsSync()) {
      _file.createSync();
    }
    _file.readAsLinesSync().forEach((String entry) {
      var parts = entry.split(_kvDelim);
      assert(parts.length == 2);
      _records[_keySerializer.deserialize(parts.first)] =
          _valueSerializer.deserialize(parts.last);
    });
  }

  @override
  Set<K> get keys => _records.keys.toSet();

  @override
  Future<V> insert(K key, V value) async {
    var oldValue = await get(key);
    if (oldValue != null) {
      throw new Exception('$key is already associated with $oldValue');
    }
    _records[key] = value;
    return value;
  }

  @override
  Future<V> update(K key, V value) async {
    if (await get(key) == null) {
      throw new Exception("No record associated with $key");
    }
    _records[key] = value;
    return value;
  }

  @override
  Future<V> get(K key) async => _records[key];

  @override
  Future<V> remove(K key) async {
    if (_records.containsKey(key)) {
      return _records.remove(key);
    }
    return null;
  }

  @override
  Future<Iterable<V>> where(bool filter(K key, V value)) async {
    var results = <V>[];

    _records.forEach((K key, V value) {
      if (filter(key, value)) {
        results.add(value);
      }
    });
    return results;
  }

  /// Writes the contents of the database to the file supplied at construction.
  Future<Null> saveOnDisk() async {
    _records.forEach((K key, V value) {
      _file
        ..writeAsStringSync(_keySerializer.serialize(key))
        ..writeAsStringSync(_kvDelim)
        ..writeAsStringSync(_valueSerializer.serialize(value));
    });
  }
}
