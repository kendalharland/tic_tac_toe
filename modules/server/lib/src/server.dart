import 'dart:async';
import 'dart:io';

import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.state/state.dart';

/// A database implementation for a tic-tac-toe game.
class TicTacToeDatabase {
  final Database<String, User> _userDatabase;
  final Database<String, Game> _gameDatabase;

  /// Creates a tic-tac-toe server.
  ///
  /// The current directory is used as the server's database root.
  factory TicTacToeDatabase() => new TicTacToeDatabase.withDatabaseRoot('.');

  /// Creates a tic-tac-toe server with the provided databases.
  ///
  /// [userDatabase] is the file to use for the [User] database.
  /// [gameDatabase] is the file to use for the [Game] database.
  TicTacToeDatabase.withDatabases(
      {Database<String, User> userDatabase,
      Database<String, Game> gameDatabase})
      : _userDatabase = userDatabase,
        _gameDatabase = gameDatabase;

  /// Creates a tic-tac-toe server.
  ///
  /// [rootDirectory] specifies the root directory for the server's database.
  factory TicTacToeDatabase.withDatabaseRoot(String rootDirectory) =>
      new TicTacToeDatabase.withDatabases(
          userDatabase: new MemoryDatabase<String, User>(
              new File('$rootDirectory/users.db'),
              new StringSerializer(),
              new UserSerializer()),
          gameDatabase: new MemoryDatabase<String, Game>(
              new File('$rootDirectory/games.db'),
              new StringSerializer(),
              new GameSerializer()));

  /// Returns the game with [name] in this database.
  ///
  /// If the game does not exist, an error is returned.
  Future<GameResponse> getGame(String name) async {
    if (_gameDatabase.containsKey(name)) {
      return new GameResponse(await _gameDatabase.get(name));
    }
    return new GameResponse.error('Game does not exist');
  }

  /// Creates a new game with [name] in this database.
  ///
  /// If the game already exists, an error is returned.
  Future<GameResponse> createGame(String name) async {
    if (_gameDatabase.containsKey(name)) {
      return new GameResponse.error('Game already exists');
    }
    return new GameResponse(
        await _gameDatabase.insert(name, new Game(name, new Board(), [])));
  }

  /// Adds the user named [userName] to the game named [gameName] if both exist.
  ///
  /// If either the user or game do not exist an error is returned
  Future<GameResponse> joinGame(String gameName, String userName) async {
    if (!_userDatabase.containsKey(userName)) {
      return new GameResponse.error('User does not exist');
    }

    if (!_gameDatabase.containsKey(gameName)) {
      return new GameResponse.error('Game does not exist');
    }
    var game = await _gameDatabase.get(gameName);
    var user = await _userDatabase.get(userName);

    var turn = Space.o;
    if (game.players.isNotEmpty) {
      if (game.players.length > 1) {
        return new GameResponse.error('Game is full');
      }
      if (game.players.single.user == user) {
        return new GameResponse.error('User is already in game');
      }
      if (game.players.single.turn == Space.o) {
        turn = Space.x;
      }
    }

    game.players.add(new Player(user, turn));
    game = await _gameDatabase.update(game.name, game);
//        game.name,
//        new Game(gameName, game.state,
//            [new Player(user, turn), game.players.single]));

    return new GameResponse(game);
  }

  /// Returns the [Board] for the game named [gameName].
  ///
  /// If the game does not exist, an error is returned.
  Future<StateResponse> getGameState(String gameName) async {
    if (!_gameDatabase.containsKey(gameName)) {
      return new StateResponse.error('Game does not exist');
    }

    return new StateResponse((await _gameDatabase.get(gameName)).state);
  }

  /// Sets [newState] as the state for the game named [gameName].
  Future<StateResponse> setGameState(String gameName, Board newState) async {
    if (!_gameDatabase.containsKey(gameName)) {
      return new StateResponse.error('Game does not exist');
    }

    var game = await _gameDatabase.get(gameName);
    if (!_isStateChangeValid(game.state, newState)) {
      return new StateResponse.error('Invalid state change');
    }

    return new StateResponse((await _gameDatabase.update(
            gameName, new Game(gameName, newState, game.players)))
        .state);
  }

  /// Adds [User] to this database
  ///
  /// If the user already exists, an error is returned.
  Future<UserResponse> addUser(User user) async {
    if (_userDatabase.containsKey(user.name)) {
      return new UserResponse.error('User already exists');
    }
    return new UserResponse([(await _userDatabase.insert(user.name, user))]);
  }

  /// Gets the user named [userName] from this database.
  ///
  /// If the user does not exist, an error is thrown.
  Future<UserResponse> getUser(String userName) async {
    if (!_userDatabase.containsKey(userName)) {
      return new UserResponse.error('User does not exist');
    }
    return new UserResponse([(await _userDatabase.get(userName))]);
  }

  /// Returns all [User]s in the game named [gameName].
  ///
  /// If the game does not exist, an error is returned.
  Future<UserResponse> getUsersInGame(String gameName) async {
    if (!_gameDatabase.containsKey(gameName)) {
      return new UserResponse.error('game with name $gameName does not exist.');
    }
    var game = await _gameDatabase.get(gameName);
    return new UserResponse(game.players.map((player) => player.user));
  }

  /// Removes the user named [userName] from the game named [gameName].
  ///
  /// If either the user or game do not exist an [Exception] is thrown.
  Future<GameResponse> removeUserFromGame(
      String userName, String gameName) async {
//    if (!_userDatabase.containsKey(userName)) {
//      return new GameResponse.error('User does not exist');
//    }
//
//    if (!_gameDatabase.containsKey(gameName)) {
//      return new GameResponse.error('Game does not exist');
//    }
//
//    var game = await _gameDatabase.get(gameName);
//    if (!game.userIds.contains(userName)) {
//      return new GameResponse.error('User is not in game');
//    }
//
//    game.players.removeWhere((player) => player.user)
//    return new GameResponse(await _gameDatabase.update(
//        gameName,
//        new Game(gameName, game.state,
//            new List.from(game.userIds)..remove(userName))));
    return new GameResponse.error('unimplemented');
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
