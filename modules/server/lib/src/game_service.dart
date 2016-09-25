import 'package:fixnum/fixnum.dart';

import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.state/state.dart';

// TODO(kharland): Stop caching game/state once database exists.
// TODO(kharland): Add method to remove games when it becomes important.
// TODO(kharland): Add method to leave games when it becomes important.
// TODO(kharland): Add method to spectate games when it becomes important.
class GameService {
  final _games = <Int64, Game>{};

  final _gameIdToState = <Int64, Board>{};
  int _gameIdCounter = 0;

  Game createGame() {
    var game = new Game(_newGameId(), const []);
    _games[game.id] = game;
    _gameIdToState[game.id] = new Board();
    return game;
  }

  Game getGame(Int64 gameId) => _games[gameId];

  Game joinGame(Int64 gameId, Int64 userId) {
    if (_games[gameId] == null) {
      return null;
    }

    var userIds = _games[gameId].userIds;
    if (userIds.length >= 2 || userIds.contains(userId)) {
      return _games[gameId];
    }

    userIds = [userId]..addAll(userIds);
    _games[gameId] = new Game(gameId, userIds);
    return _games[gameId];
  }

  Board getGameState(Int64 gameId) => _gameIdToState[gameId];

  Board updateGameState(Int64 gameId, Board newState) {
    if (_isStateChangeValid(gameId, newState)) {
      _gameIdToState[gameId] = newState;
      return newState;
    } else {
      return _gameIdToState[gameId];
    }
  }

  bool _isStateChangeValid(Int64 gameId, Board newState) {
    if (_games[gameId] == null ||
        _gameIdToState[gameId] == null ||
        _gameIdToState[gameId].isOver()) {
      return false;
    }

    var turn = _gameIdToState[gameId].getTurn();
    var oldValues = _gameIdToState[gameId].toValues();
    var newValues = newState.toValues();
    bool foundOneChange = false;

    for (int i = 0; i < oldValues.length; i++) {
      if (oldValues[i] != newValues[i]) {
        if (oldValues[i] != Space.empty ||
            newValues[i] != turn ||
            foundOneChange) {
          return false;
        }
        foundOneChange = true;
      }
    }
    return true;
  }

  Int64 _newGameId() => new Int64(++_gameIdCounter);
}
