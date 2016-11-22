import 'dart:async';
import 'dart:io';
import 'package:tic_tac_toe.database/serializer.dart';

/// A very naive key-value store.
abstract class Database<K, V> {
  /// Whether this [Database] contains and entry for [key].
  bool containsKey(K key);

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
/// The contents can be written to disk via [writeToFile].
class MemoryDatabase<K, V> implements Database<K, V> {
  final File _file;
  final Serializer<K> _keySerializer;
  final Serializer<V> _valueSerializer;
  final String _kvDelim = '«';
  final Map<K, V> _records = <K, V>{};

  MemoryDatabase(this._file, this._keySerializer, this._valueSerializer) {
    if (!_file.existsSync()) {
      _file.createSync();
    }
    _file.openSync();
    _file.readAsLinesSync().forEach((String entry) {
      var parts = entry.split(_kvDelim);
      assert(parts.length == 2);
      _records[_keySerializer.deserialize(parts.first)] =
          _valueSerializer.deserialize(parts.last);
    });
  }

  @override
  bool containsKey(K key) => _records.containsKey(key);

  @override
  Future<V> insert(K key, V value) async {
    var oldValue = await get(key);
    if (oldValue != null) {
      throw new Exception('$key is already associated with $oldValue');
    }
    _records[key] = value;
    await writeToFile();
    return value;
  }

  @override
  Future<V> update(K key, V value) async {
    if (await get(key) == null) {
      throw new Exception("No record associated with $key");
    }
    _records[key] = value;
    await writeToFile();
    return value;
  }

  @override
  Future<V> get(K key) async => _records[key];

  @override
  Future<V> remove(K key) async {
    if (_records.containsKey(key)) {
      var record = _records.remove(key);
      await writeToFile();
      return record;
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
  Future<Null> writeToFile() async {
    String data = '';
    _records.forEach((K key, V value) {
      data = '$data'
          '${_keySerializer.serialize(key)}'
          '$_kvDelim'
          '${_valueSerializer.serialize(value)}\n';
    });
    _file.writeAsStringSync(data);
  }
}
