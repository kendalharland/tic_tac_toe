import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.state/state.dart';

class Client {
  static String _marshall(Object decodedJson) =>
      Uri.encodeFull(JSON.encode(decodedJson));

  static Object _unmarshall(String encodedMessage) =>
      JSON.decode(Uri.decodeFull(encodedMessage));

  final String _serverUrl;

  Client(String server, int port) : _serverUrl = 'http://$server:$port';

  /// Log's into the server, or registers the user if it doesn't yet exist.
  Future<User> login(User user) async {
    var result = _unmarshall(await _get('user/${user.id}'));
    var message = new UserResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print('Login failed. Registering user...');
      return _register(user);
    }
    return message.users.single;
  }

  Future<User> _register(User user) async {
    var result = _unmarshall(await _post('user/${user.id}/${user.name}'));
    var message = new UserResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print('Could not register user ${user.name}...');
      return new User(new Int64(-1), '');
    }
    return message.users.single;
  }

  /// Gets the game with name [name] if one exists.
  Future<Game> getGame(String name) async {
    var result = _unmarshall(await _get('game/$name'));
    var message = new GameResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print(message.message);
    }
    return message.game;
  }

  /// Creates a game and joins this client to that game.
  ///
  /// If the game could not be created an error is thrown.
  Future<Game> createGame(String name) async {
    var result = _unmarshall(await _post('game/$name'));
    var message = new GameResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print(message.message);
    }
    return message.game;
  }

  /// Joins this client to the game with id [gameId].
  ///
  /// If the game does not exist, an error is thrown.
  Future<Game> joinGame(User user, String gameId) async {
    var result = _unmarshall(await _get('game/join/$gameId/${user.id}'));
    var message = new GameResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print(message.message);
    }
    return message.game;
  }

  /// Gets the state of the game with id [gameName].
  ///
  /// If the game does not exist, an error is thrown.
  Future<Board> getGameState(String gameName) async {
    var result = _unmarshall(await _get('game/state/$gameName'));
    var message = new StateResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print(message.message);
    }
    return message.state;
  }

  /// Updates the game with id [gameName] with the specified [state].
  ///
  /// If [state] represents an invalid update, an error is thrown.
  Future<Board> updateGameState(String gameName, Board state) async {
    var encodedState = _marshall(state.toJson());
    var result = _unmarshall(await _put('game/state/$gameName/$encodedState'));
    var message = new StateResponse.fromJson(result as Map<String, Object>);
    if (message.message.isNotEmpty) {
      print(message.message);
    }
    return message.state;
  }

  Future<String> _get(String action) =>
      _execute(action, new HttpClient().getUrl);

  Future<String> _post(String action) =>
      _execute(action, new HttpClient().postUrl);

  Future<String> _put(String action) =>
      _execute(action, new HttpClient().putUrl);

  Future<String> _execute(
          String action, Future<HttpClientRequest> method(Uri url)) =>
      method(Uri.parse('$_serverUrl/$action'))
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) =>
              response.transform(UTF8.decoder).join());
}

class Player {
  final User _user;
  final Client _client;
  final Space _turn;
  Game _game;

  Player(this._user, this._client, this._game, this._turn);

//  String get name => _user.name;
//
  Space get turn => _turn;
//
//  Game get game => _game;

  Future<bool> move(int space) async {
    await _verifyStillInGame();
    if (_game.state.getTurn() != _turn) {
      print("not your turn in game ${_game.name}.");
      print("turn is ${_game.state.getTurn()} and you are ${_turn}");
      print('which ${_game.state.getTurn() == _turn}');
      return false;
    }
    space = 10 - space;
    var newSpaces = new List<Space>.from(_game.state.toValues())
      ..replaceRange(space - 1, space, [_turn]);
    var oldBoard = _game.state;
    var newBoard = await _client.updateGameState(
        _game.name,
        new Board.fromSpaces([
          newSpaces.getRange(0, 3),
          newSpaces.getRange(3, 6),
          newSpaces.getRange(6, 9)
        ]));
    return !newBoard.isBlank() && oldBoard.getTurn() != newBoard.getTurn();
  }

  Future<Null> _verifyStillInGame() async {
    if (_game == null) {
      throw new Exception('Was never in game');
    }
    var game = await _client.getGame(_game.name);
    if (!game.userIds.contains(_user.id)) {
      throw new Exception('No longer in game ${game.name}');
    }
    _game = game;
  }
}

/// A little client demo.
Future main(List<String> args) async {
  final client = new Client('localhost', 8080);
  final gameName = args.last;
  var user = new User(Int64.parseInt(args[1]), args.first);

  print("-- Logging in...");
  var loggedInUser = await client.login(user);
  if (loggedInUser.name.isEmpty) {
    print("-- Failed to log as ${user.name}");
    return;
  }
  user = loggedInUser;
  print("-- Logged in as ${user.name}");

  print("-- Finding game $gameName...");
  var game = await client.getGame(gameName);
  if (game.name.isEmpty) {
    print("-- Game $gameName not found. Creating it...");
    game = await client.createGame(gameName);
    print('-- Created game ${game.name}');
  } else {
    print("-- Found game $gameName...");
  }

  if (!game.userIds.contains(user.id)) {
    print("-- Joining game ${game.name}...");
    game = await client.joinGame(user, game.name);
    if (game.name.isNotEmpty) {
      print('-- Joined game ${game.name}');
    }
  } else {
    print('-- Already in game');
  }

  var turn = game.state.getTurn();
  if (game.userIds.length > 1) {
    turn = turn == Space.x ? Space.o : Space.x;
  }

  var player = new Player(user, client, game, turn);


}

void _prettyPrintBoard(Board board) {
  String _spaceToString(Space space) {
    switch (space) {
      case Space.x:
        return 'x';
      case Space.o:
        return 'o';
      default:
        return '_';
    }
  }

  var spaces = board.toValues();
  for (int i = 0; i < spaces.length; i++) {
    stdout.write('${_spaceToString(spaces[i])} ');
    if ((i + 1) % 3 == 0) stdout.writeln();
  }
}
