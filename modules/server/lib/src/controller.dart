import 'dart:async';
import 'package:fixnum/fixnum.dart';

import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.server/src/auth_service.dart';
import 'package:tic_tac_toe.server/src/game_service.dart';
import 'package:tic_tac_toe.state/state.dart';

export 'package:tic_tac_toe.server/src/auth_service.dart';
export 'package:tic_tac_toe.server/src/game_service.dart';

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
