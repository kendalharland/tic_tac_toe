import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.state/state.dart';

/// A database implementation for a tic-tac-toe game.
class Server {
  final Database<Int64, User> _userDatabase;
  final Database<String, Game> _gameDatabase;

  /// Creates a tic-tac-toe server with the provided databases.
  ///
  /// [users] is the file to use for the [User] database.
  ///
  /// [games] is the file to use for the [Game] database.
  Server.withDatabases(
      {Database<Int64, User> userDatabase, Database<String, Game> gameDatabase})
      : _userDatabase = userDatabase,
        _gameDatabase = gameDatabase;

  /// Creates a tic-tac-toe server.
  ///
  /// [root] specifies the root directory for the server's database.
  factory Server.withDatabaseRoot(String root) => new Server.withDatabases(
      userDatabase: new MemoryDatabase<Int64, User>(new File('$root/users.db'),
          new Int64Serializer(), new UserSerializer()),
      gameDatabase: new MemoryDatabase<String, Game>(new File('$root/games.db'),
          new StringSerializer(), new GameSerializer()));

  /// Creates a tic-tac-toe server.
  ///
  /// The current directory is used as the server's database root.
  factory Server() => new Server.withDatabaseRoot('.');

  /// Creates a new game with [name] in this database.
  ///
  /// If the game already exists, an error is returned.
  Future<GameMessage> createGame(String name) async {
    Game game;

    if (!_gameDatabase.containsKey(name)) {
      game = await _gameDatabase.insert(name, new Game(name, new Board(), []));
    } else {
      return new GameMessage(null, 'Game already exists');
    }

    return new GameMessage(game);
  }

  /// Adds the user with id [userId] to the game named [gameName] if both exist.
  ///
  /// If either the user or game do not exist an error is returned
  Future<GameMessage> joinGame(String gameName, Int64 userId) async {
    if (!_userDatabase.containsKey(userId)) {
      return new GameMessage(null, 'User does not exist');
    }

    if (!_gameDatabase.containsKey(gameName)) {
      return new GameMessage(null, 'Game does not exist');
    }

    var game = await _gameDatabase.get(gameName);
    if (game.userIds.contains(userId)) {
      return new GameMessage(null, 'User is already in game');
    }

    game = await _gameDatabase.update(gameName,
        new Game(gameName, game.state, [userId]..addAll(game.userIds)));
    if (!game.userIds.contains(userId)) {
      return new GameMessage(null, 'Unable to join game');
    }

    return new GameMessage(game);
  }

  /// Returns the [Board] for the game named [gameName].
  ///
  /// If the game does not exist, an error is returned.
  Future<StateMessage> getGameState(String gameName) async {
    if (_gameDatabase.containsKey(gameName)) {
      return new StateMessage(null, 'Game does not exist');
    }

    return new StateMessage((await _gameDatabase.get(gameName)).state);
  }

  /// Sets [newState] as the state for the game named [gameName].
  Future<StateMessage> setGameState(String gameName, Board newState) async {
    Game game;

    if (!_gameDatabase.containsKey(gameName)) {
      return new StateMessage(null, 'Game does not exist');
    }

    game = await _gameDatabase.get(gameName);
    if (!_isStateChangeValid(game.state, newState)) {
      return new StateMessage(null, 'Invalid state change');
    }

    return new StateMessage((await _gameDatabase.update(
            gameName, new Game(gameName, newState, game.userIds)))
        .state);
  }

  /// Returns all [User]s in the game named [gameName].
  ///
  /// If the game does not exist, an error is returned.
  Future<UserMessage> getUsersInGame(String gameName) async {
    if (!_gameDatabase.containsKey(gameName)) {
      return new UserMessage(null, 'game with name $gameName does not exist.');
    }
    return new UserMessage((await Future.wait(
        (await _gameDatabase.get(gameName)).userIds.map(_userDatabase.get))));
  }

  /// Removes the user with id [userId] from the game named [gameName].
  ///
  /// If either the user or game do not exist an [Exception] is thrown.
  Future<GameMessage> removeUserFromGame(Int64 userId, String gameName) async {
    if (!_userDatabase.containsKey(userId)) {
      return new GameMessage(null, 'User does not exist');
    }

    if (!_gameDatabase.containsKey(gameName)) {
      return new GameMessage(null, 'Game does not exist');
    }

    var game = await _gameDatabase.get(gameName);
    if (!game.userIds.contains(userId)) {
      return new GameMessage(null, 'User is not in game');
    }

    return new GameMessage(await _gameDatabase.update(
        gameName,
        new Game(gameName, game.state,
            new List.from(game.userIds)..remove(userId))));
  }

  bool _isStateChangeValid(Board oldState, Board newState) {
    if (oldState.isOver() || oldState == newState) {
      return false;
    }

    var oldValues = oldState.toValues();
    var newValues = newState.toValues();
    bool foundOneChange = false;

    for (int i = 0; i < oldValues.length; i++) {
      if (oldValues[i] != newValues[i]) {
        if (oldValues[i] != Space.empty ||
            newValues[i] != oldState.getTurn() ||
            foundOneChange) {
          return false;
        }
        foundOneChange = true;
      }
    }
    return true;
  }
}
