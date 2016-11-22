import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:distributed/distributed.dart';
import 'package:distributed/platform/io.dart';
import 'package:fixnum/fixnum.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.state/state.dart';

Node node;
Peer server;
Game game;
Player player;
Player otherPlayer;

Future main(List<String> args) async {
  configureDistributed();
  String gameName = args.first;
  var user = new User(Int64.ONE, args[1]);
  node = await createNode(user.name, 'localhost', 'cookie', port: int.parse(args.last));
  server = new Peer('tic_tac_toe', 'localhost', port: 9095);

  node.onConnect.listen((Peer peer) {
    assert(peer.name == server.name);
    print('Logging into ${server.displayName}..');
    node.send(server, addUser, JSON.encode(user.toJson()));
  });

  node.receive(addUserResponse).listen((Message message) {
    var response = new UserResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
      node.send(server, getUser, JSON.encode(user.toJson()));
    } else {
      user = response.users.single;
      print('Logged into ${server.displayName}');
      node.send(message.sender, getGame, gameName);
    }
  });

  node.receive(getUserResponse).listen((Message message) {
    var response = new UserResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
      node.send(message.sender, addUser, JSON.encode(user.toJson()));
    } else {
      user = response.users.single;
      print('Logged into ${server.displayName}');
      node.send(message.sender, getGame, gameName);
    }
  });

  node.receive(getGameResponse).listen((Message message) {
    var response = new GameResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
      game = new Game(gameName, new Board(), []);
      node.send(message.sender, createGame, JSON.encode(game.toJson()));
    } else {
      game = response.game;
      if (game.players.any((player) => player.user == user)) {
        player = game.players.firstWhere((player) => player.user == user);
        otherPlayer = game.players
            .firstWhere((player) => player.user != user, orElse: () => null);
        getMove();
      } else {
        print('Joining game ${game.name}...');
        node.send(message.sender, joinGame,
            JSON.encode([game.toJson(), user.toJson()]));
      }
    }
  });

  node.receive(createGameResponse).listen((Message message) {
    var response = new GameResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
    } else {
      print('Joining game $game...');
      node.send(message.sender, joinGame,
          JSON.encode([game.toJson(), user.toJson()]));
    }
  });

  node.receive(joinGameResponse).listen((Message message) {
    var response = new GameResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
    } else {
      game = response.game;
      print('Joined game $game...');
      player = game.players.firstWhere((player) => player.user == user);
      otherPlayer = game.players
          .firstWhere((player) => player.user != user, orElse: () => null);
      getMove();
    }
  });

  node.receive(opponentJoinedResponse).listen((Message message) {
    var response = new GameResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
    } else {
      print('Opponent joined game');
      game = response.game;
      otherPlayer = game.players
          .firstWhere((player) => player.user != user);
      getMove();
    }
  });

  node.receive(setGameStateResponse).listen((Message message) {
    var response = new StateResponse.fromString(message.data);
    if (response.isError) {
      print(response.message);
    } else {
      game = new Game(game.name, response.state, game.players);
      getMove();
    }
  });

  node.connectTo(server);
}

Future getMove() async {
  String input;

  while (true) {
    if (game.state.isOver()) {
      print('Game over');
      return;
    }

    prettyPrintBoard(game.state);

    if (game.state.getTurn() != player.turn) {
      if (otherPlayer == null) {
        print("Waiting for another player");
      } else {
        print("Waiting for ${otherPlayer.user.name} move...");
      }
      return;
    }

    stdout.write('Your turn. choose a space [1-9]: ');
    input = stdin.readLineSync();
    try {
      await move(int.parse(input.trim()));
      break;
    } catch (e) {
      print('invalid input. ');
    }
  }
}

void prettyPrintBoard(Board board) {
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

Future<bool> move(int space) async {
  space = 10 - space;
  var newSpaces = new List<Space>.from(game.state.toValues())
    ..replaceRange(space - 1, space, [game.state.getTurn()]);
  node.send(
      server,
      setGameState,
      JSON.encode([
        game.toJson(),
        new Board.fromSpaces([
          newSpaces.getRange(0, 3),
          newSpaces.getRange(3, 6),
          newSpaces.getRange(6, 9)
        ]).toJson()
      ]));
  return true;
}
