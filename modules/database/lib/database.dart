import 'package:fixnum/fixnum.dart';

class TicTacToeDatabase {
  final Database _userDatabase;
  final Database _gameDatabase;

  TicTacToeDatabase(String directory)
      : _userDatabase = new _FlatFileDatabase<User>(
            '$directory/users.db', new UserSerializer()),
        _gameDatabase = new _FlatFileDatabase<Board>(
            '$directory/games.db', new BoardSerializer());

  Stream<Iterable<User>> getAllUsers();

  Future<User> getUser(Int64 userId);

  Stream<Iterable<User>> getGameUsers(Int64 gameId);

  Stream<Iterable<Board>> getAllGames();

  Future<Board> insertGame();

  Future<Board> removeGame(Int64 gameId);

  Future<Board> getGame(Int64 gameId);

  Future<Board> setGame(Board state);

  Future<Game> addUserToGame(Int64 userId, Int64 gameId);

  Future<Game> removeUserFromGame(Int64 userId, Int64 gameId);
}

abstract class Database<K, V> {
  Future<V> insert(K key, V value);

  Future<V> update(K key, V value);

  Future<V> get(K key);

  Future<V> remove(K key);
  
  // Future<Null> shutdown();
}

class FlatFileDatabase<V> implements Database<String, V> {
  final File _file;
  final Serializer _serializer;
  final String _kvDelim = '«';
  final Map<String, T> _records;
  
  FlatFileDatabase(this._file, this._serializer) {
    assert(_file.existsSync());
    _file.readAsLinesSync().forEach((String entry) {
      var parts = entry.split(_kvDelim);
      assert(parts.length == 2);
      _records[parts.first] = _serializer.serialize(parts.last);
    });
  }

  @override
  Future<V> insert(String key, V value) async {
    var oldValue = await get(key);
    if (oldValue != null) {
      throw new Exception('$key is already associated with $oldValue');
    }
    _records[key] = _serializer.serialize(value);
    return value;
  }

  @override
  Future<V> update(K key, V value) async {
    if (await get(key) == null) {
      throw new Exception("No record associated with $key");
    }
    _records[key] = _serializer.serialize(value);
    return value;
  }

  @override
  Future<V> get(K key) {
    if (_records.containsKey(key)) {
      return _serializer.deserialize(_records[key]);
    }
    return null;
  }

  @override
  Future<V> remove(K key) async {
    var value = await get(key);
    if (value == null) {
      return null;
    }
    return _serializer.deserialize(value);
  }
  
  
  // @override
  // Future<Null> shutdown()
  
}
