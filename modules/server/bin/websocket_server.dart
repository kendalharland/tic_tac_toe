import 'dart:async';
import 'dart:convert';

import 'package:distributed/distributed.dart';
import 'package:distributed/platform/io.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.server/src/server.dart';
import 'package:tic_tac_toe.state/state.dart';

class Server {
  final Node _node;
  final Map<User, Peer> _user2Peer = <User, Peer>{};
  final _database = new TicTacToeDatabase.withDatabaseRoot('.');

  Server(this._node) {
    _node.onConnect.listen((Peer peer) {
      print('${peer.displayName} connected.');
    });

    _node.onDisconnect.listen((Peer peer) {
      print('${peer.displayName} disconnected.');
    });

    _node.receive(addUser).listen((Message message) {
      print('ADD USER: ${message.sender.displayName}');
      var user =
          new User.fromJson(JSON.decode(message.data) as Map<String, Object>);
      _database.addUser(user).then((UserResponse response) {
        _node.send(
            message.sender, addUserResponse, JSON.encode(response.toJson()));
      });
    });

    _node.receive(getUser).listen((Message message) {
      print('GET USER: ${message.sender.displayName}');
      var user =
          new User.fromJson(JSON.decode(message.data) as Map<String, Object>);
      _database.getUser(user.name).then((UserResponse response) {
        _node.send(
            message.sender, getUserResponse, JSON.encode(response.toJson()));
      });
    });

    _node.receive(getGame).listen((Message message) {
      print('GET GAME: ${message.sender.displayName}');
      _database.getGame(message.data).then((GameResponse response) {
        _node.send(
            message.sender, getGameResponse, JSON.encode(response.toJson()));
      });
    });

    _node.receive(createGame).listen((Message message) {
      print('CREATE GAME: ${message.sender.displayName} ${message.data}');
      var game =
          new Game.fromJson(JSON.decode(message.data) as Map<String, Object>);
      _database.createGame(game.name).then((GameResponse response) {
        _node.send(
            message.sender, createGameResponse, JSON.encode(response.toJson()));
      });
    });

    _node.receive(joinGame).listen((Message message) {
      print('JOIN GAME: ${message.sender.displayName}');
      var args = JSON.decode(message.data) as List<Map<String, Object>>;
      var game = new Game.fromJson(args.first);
      var user = new User.fromJson(args.last);
      _database.getGame(game.name).then((GameResponse response) {
        if (response.isError) {
          _node.send(
              message.sender, joinGameResponse, JSON.encode(response.toJson()));
        } else {
          _user2Peer[user] = message.sender;
          _database
              .joinGame(game.name, user.name)
              .then((GameResponse joinedResponse) {
            _node.send(message.sender, joinGameResponse,
                JSON.encode(joinedResponse.toJson()));
            if (joinedResponse.game.players.length > 1) {
              var otherPlayer = joinedResponse.game.players
                  .firstWhere((player) => player.user != user);
              var otherPeer = _user2Peer[otherPlayer.user];
              _node.send(otherPeer, opponentJoinedResponse,
                  JSON.encode(joinedResponse.toJson()));
            }
          });
        }
      });
    });

    _node.receive(setGameState).listen((Message message) {
      print('UPDATE GAME: ${message.sender.displayName}');
      var args = JSON.decode(message.data) as List<Object>;
      var game = new Game.fromJson(args.first as Map<String, Object>);
      var state = new Board.fromJson(args.last as List<List<String>>);
      _database.setGameState(game.name, state).then((StateResponse response) {
        game.players.forEach((player) {
        _node.send(_user2Peer[player.user], setGameStateResponse,
            JSON.encode(response.toJson()));
        });
      });
    });
  }
}

Future main() async {
  configureDistributed();
  new Server(
      await createNode('tic_tac_toe', 'localhost', 'cookie', port: 9095));
}
