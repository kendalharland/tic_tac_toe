import "dart:io";
import "dart:async";
import "dart:convert";

import "package:fixnum/fixnum.dart";
import "package:tic_tac_toe.state/state.dart";
import "package:tic_tac_toe.net/src/messages.dart";

class Client {
  String _marshall(Object decodedJson) =>
      Uri.encodeFull(JSON.encode(decodedJson));

  Object _unmarshall(String encodedMessage) =>
      JSON.decode(Uri.decodeFull(encodedMessage));

  final Int64 _userId;
  final String _SERVER_URL;

  Client(this._userId, String serverHostname, int serverPort)
      : _SERVER_URL = 'http://$serverHostname:$serverPort';

  /// Creates a game and joins this client to that game.
  ///
  /// If the game could not be created an error is thrown.
  Future<Game> createGame() async {
    var action = "game/create";
    var result = _unmarshall(await _execute(action));
    var message = new GameMessage.fromJson(result);
    if (message.errors.isEmpty) {
      print("Game created");
      return joinGame(message.game.id);
    } else {
      throw message.errors;
    }
  }

  /// Joins this client to the game with id [gameId].
  ///
  /// If the game does not exist, an error is thrown.
  Future<Game> joinGame(Int64 gameId) async {
    var action = "game/join/$gameId/$_userId";
    var result = _unmarshall(await _execute(action));
    var message = new GameMessage.fromJson(result);
    if (message.errors.isEmpty) {
      return message.game;
    } else {
      throw message.errors;
    }
  }

  /// Gets the state of the game with id [gameId].
  ///
  /// If the game does not exist, an error is thrown.
  Future<Board> getGameState(Int64 gameId) async {
    var action = "game/state/get/$gameId";
    var result = _unmarshall(await _execute(action));
    var message = new StateMessage.fromJson(result);
    if (message.errors.isEmpty) {
      return message.state;
    } else {
      throw message.errors;
    }
  }

  /// Updates the game with id [gameId] with the specified [state].
  ///
  /// If [state] represents an invalid update, an error is thrown.
  Future<Board> updateGameState(Int64 gameId, Board state) async {
    var encodedState = _marshall(state.toJson());
    var action = "game/state/update/$gameId/$encodedState";
    var result = _unmarshall(await _execute(action));
    var message = new StateMessage.fromJson(result);
    if (message.errors.isEmpty) {
      return message.state;
    } else {
      throw message.errors;
    }
  }

  Future<String> _execute(String action) {
    return new HttpClient()
        .getUrl(Uri.parse('$_SERVER_URL/$action'))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.transform(UTF8.decoder).join());
  }
}

/// A little client demo.
Future main() async {
  var kendal = new Client(KENDAL.id, 'localhost', 8080);
  var matan = new Client(MATAN.id, 'localhost', 8080);

  var game = await kendal.createGame();
  var joinedGame = await matan.joinGame(game.id);
  print(joinedGame);

  var state = await kendal.getGameState(game.id);
  print(state);

  var firstTurn = await matan.updateGameState(
      game.id,
      new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
      ]));
  print(firstTurn);
}
