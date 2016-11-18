import 'dart:async';
import 'dart:io';

import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';

import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.server/src/auth_service.dart';
import 'package:tic_tac_toe.server/src/game_service.dart';
import 'package:tic_tac_toe.state/state.dart';

export 'package:tic_tac_toe.server/src/auth_service.dart';
export 'package:tic_tac_toe.server/src/game_service.dart';

import 'package:fixnum/fixnum.dart';

/// A database implementation for a tic-tac-toe game.
class TicTacToeDatabase {
  static final Int64Serializer _commonKeySerializer = new Int64Serializer();
  final InMemoryDatabase<Int64, User> _userDatabase;
  final InMemoryDatabase<Int64, Board> _boardDatabase;
  final InMemoryDatabase<Int64, Game> _gameDatabase;
  /// Cross-reference database that maps a [Game] to a [Board].
  final InMemoryDatabase<Int64, Int64> _gameToStateDatabase;
  /// Cross-reference database that maps a [User] to a [Game].
  final InMemoryDatabase<Int64, Iterable<Int64>> _userToGameDatabase;

  /// Creates a database for a tic-tac-toe game.
  TicTacToeDatabase(String directory)
      : _userDatabase = new InMemoryDatabase<Int64, User>(
            new File('$directory/users.db'),
            _commonKeySerializer,
            new UserSerializer()),
        _boardDatabase = new InMemoryDatabase<Int64, Board>(
            new File('$directory/boards.db'),
            _commonKeySerializer,
            new BoardSerializer()),
        _gameDatabase = new InMemoryDatabase<Int64, Game>(
            new File('$directory/games.db'),
            _commonKeySerializer,
            new GameSerializer()),
        _gameToStateDatabase = new InMemoryDatabase<Int64, Int64>(
            new File('$directory/games_boards.db'),
            _commonKeySerializer,
            _commonKeySerializer),
        _userToGameDatabase = new InMemoryDatabase<Int64, Iterable<Int64>>(
            new File('$directory/users_games.db'),
            _commonKeySerializer,
            new IterableSerializer(_commonKeySerializer));

  /// Returns true iff this database contains a [User] with id [userId].
  bool containsUser(Int64 userId) => _userDatabase.keys.contains(userId);

  /// Returns the [User] with id [userId].
  Future<User> getUser(Int64 userId) => _userDatabase.get(userId);

  /// Adds [user] to this database.
  Future<User> addUser(User user) => _userDatabase.insert(user.id, user);

  /// Returns all [User]s in the game with id [gameId].
  Stream<Iterable<User>> getUsersInGame(Int64 gameId) => _gameDatabase
      .get(gameId)
      .then((Game game) async => await Future.wait(game.userIds.map(getUser)))
      .asStream();

  Future<Game> addGame(Game game) {}

  Future<Board> removeGame(Int64 gameId);

  Future<Board> getGame(Int64 gameId);

  Future<Board> setGame(Board state);

  Future<Game> addUserToGame(Int64 userId, Int64 gameId);

  Future<Game> removeUserFromGame(Int64 userId, Int64 gameId);
}

class Controller {
  final GameService _gameService;
  final AuthService _authService;

  Controller.fromServices(this._gameService, this._authService);

  Controller()
      : _gameService = new GameService(),
        _authService = new AuthService();

  Future<GameMessage> createGame() async =>
      new GameMessage(_gameService.createGame(), []);

  Future<GameMessage> joinGame(Int64 gameId, Int64 userId) async {
    if (!_authService.isUserValid(userId)) {
      return new GameMessage(null, ["Invalid user id $userId"]);
    }

    var game = _gameService.getGame(gameId);
    if (game == null) {
      return new GameMessage(null, ["Game does not exist"]);
    }
    if (game.userIds.contains(userId)) {
      return new GameMessage(game, ["Already in game"]);
    }

    game = _gameService.joinGame(gameId, userId);
    if (!game.userIds.contains(userId)) {
      return new GameMessage(game, ["Unable to join game"]);
    }
    return new GameMessage(game, const []);
  }

  Future<StateMessage> getGameState(Int64 gameId) async {
    var state = _gameService.getGameState(gameId);
    if (state == null) {
      return new StateMessage(null, ['Game does not exist']);
    }
    return new StateMessage(state, const []);
  }

  Future<StateMessage> updateGameState(Int64 gameId, Board newState) async {
    var oldState = _gameService.getGameState(gameId);
    if (oldState == null) {
      return new StateMessage(null, ["Game does not exist"]);
    }

    newState = _gameService.updateGameState(gameId, newState);
    if (oldState == newState) {
      return new StateMessage(oldState, ["Could not update game state"]);
    }
    return new StateMessage(newState, []);
  }
}
