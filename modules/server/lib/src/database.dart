import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.state/state.dart';

/// A database implementation for a tic-tac-toe game.
class TicTacToeDatabase {
  final MemoryDatabase<Int64, User> _userDatabase;
  final MemoryDatabase<String, Game> _gameDatabase;

  /// Creates a database for a tic-tac-toe game.
  TicTacToeDatabase(String directory)
      : _userDatabase = new MemoryDatabase<Int64, User>(
            new File('$directory/users.db'),
            new Int64Serializer(),
            new UserSerializer()),
        _gameDatabase = new MemoryDatabase<String, Game>(
            new File('$directory/games.db'),
            new StringSerializer(),
            new GameSerializer());

  bool containsGame(String name) => _gameDatabase.keys.contains(name);

  bool containsUser(Int64 id) => _userDatabase.keys.contains(id);

  /// Returns the [User] with id [userId].
  Future<User> getUser(Int64 userId) => _userDatabase.get(userId);

  /// Adds [user] to this database.
  Future<User> addUser(User user) => _userDatabase.insert(user.id, user);

  /// Adds [game] to this database.
  Future<Game> addGame(Game game) => _gameDatabase.insert(game.name, game);

  /// Removes the game named [name] from this database, if it exists.
  Future<Game> removeGame(String name) => _gameDatabase.remove(name);

  /// Returns the game named [name] in this database, if it exists.
  Future<Game> getGame(String name) => _gameDatabase.get(name);

  /// Returns all [User]s in the game named [name].
  ///
  /// If the game does not exist, an [Exception] is thrown.
  Stream<Iterable<User>> getUsersInGame(String name) async* {
    var game = await _gameDatabase.get(name);
    if (game == null) {
      throw new Exception('game with name $name does not exist.');
    }
    yield* Future.wait(game.userIds.map(getUser)).asStream();
  }

  /// Sets [state] as the state for the game named [gameName].
  Future<Game> setGameState(String gameName, Board state) async {
    var game = await getGame(gameName);
    return _gameDatabase.update(
        gameName, new Game(gameName, state, game.userIds));
  }

  /// Adds the user with id [userId] to the game named [gameName] if both exist.
  ///
  /// If either the user or game do not exist an [Exception] is thrown.
  Future<Game> addUserToGame(Int64 userId, String gameName) async {
    var user = await getUser(userId);
    if (user == null) {
      throw new Exception('user with id $userId does not exist.');
    }

    var game = await getGame(gameName);
    if (game == null) {
      throw new Exception('game with id $gameName does not exist.');
    }

    return _gameDatabase.update(gameName,
        new Game(gameName, game.state, [userId]..addAll(game.userIds)));
  }

  /// Removes the user with id [userId] from the game named [gameName].
  ///
  /// If either the user or game do not exist an [Exception] is thrown.
  Future<Game> removeUserFromGame(Int64 userId, String gameName) async {
    var user = await getUser(userId);
    if (user == null) {
      throw new Exception('user with id $userId does not exist.');
    }

    var game = await getGame(gameName);
    if (game == null) {
      throw new Exception('game with id $gameName does not exist.');
    }

    return _gameDatabase.update(
        gameName,
        new Game(
            gameName, game.state, new List.from(game.userIds)..remove(userId)));
  }
}
