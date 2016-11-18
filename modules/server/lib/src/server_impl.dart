import 'dart:async';
import 'package:fixnum/fixnum.dart';

import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.server/src/database.dart';
import 'package:tic_tac_toe.state/state.dart';

class TicTacToeServer {
  final TicTacToeDatabase _database;

  TicTacToeServer(this._database);

  Future<GameMessage> createGame(String name) async {
    var errors = <String>[];
    Game game;

    if (!_database.containsGame(name)) {
      game = await _database.addGame(new Game(name, new Board(), []));
    } else {
      errors.add('Game already exists');
    }

    return new GameMessage(game, errors);
  }

  Future<GameMessage> joinGame(String gameName, Int64 userId) async {
    var errors = <String>[];

    if (!_database.containsUser(userId)) {
      errors.add('User does not exist');
    }

    if (!_database.containsGame(gameName)) {
      errors.add('Game does not exist');
    }

    var game = await _database.getGame(gameName);
    if (game.userIds.contains(userId)) {
      errors.add('User is already in game');
    }

    game = await _database.addUserToGame(userId, gameName);
    if (!game.userIds.contains(userId)) {
      errors.add('Unable to join game');
    }
    return new GameMessage(game, errors);
  }

  Future<StateMessage> getGameState(String gameName) async {
    var errors = <String>[];
    Board state;

    if (!_database.containsGame(gameName)) {
      state = (await _database.getGame(gameName)).state;
    } else {
      errors.add('Game does not exist');
    }

    return new StateMessage(state, errors);
  }

  Future<StateMessage> updateGameState(String gameName, Board newState) async {
    var errors = <String>[];
    Board state;

    if (!_database.containsGame(gameName)) {
      state = (await _database.getGame(gameName)).state;
    } else {
      errors.add('Game does not exist');
    }

    if (_isStateChangeValid(state, newState)) {
      state = (await _database.setGameState(gameName, newState)).state;
    } else {
      errors.add('Invalid state change');
    }

    return new StateMessage(state, errors);
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
