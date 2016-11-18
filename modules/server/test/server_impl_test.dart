import 'dart:async';

import 'dart:io';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.server/src/database.dart';
import 'package:tic_tac_toe.server/src/server_impl.dart';
import 'package:tic_tac_toe.state/state.dart';
import 'package:tic_tac_toe.net/src/messages.dart';

import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  TicTacToeServer server;
  TicTacToeDatabase database;
  MockTicTacToeDatabase mockDatabase;

  final startState = new Board.fromSpaces([
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty]
  ]);

  final startMove = [
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.x],
  ];

  group('$TicTacToeServer', () {
    setUp(() {
      mockDatabase = new MockTicTacToeDatabase();
      database = new TicTacToeDatabase('.');
      server = new TicTacToeServer(database);
    });

    group('createGame', () {
      test('should complete with an error if a game with the given name exists',
          () async {
//      when(mockDatabase.containsGame('A')).thenReturn(true);
        database.addGame(new Game('A', new Board(), []));
        expect((await server.createGame('A')).errors, isNotEmpty);
      });

      test('should complete with a GameMessage containing a new game',
          () async {
        var message = await server.createGame('A');
        expect(message, new isInstanceOf<GameMessage>());
        expect(message.game.userIds, isEmpty);
        expect(message.game.state, startState);
      });
    });
    /*
  group('joinGame', () {
    test('should complete with an error if the game does not exist', () async {
      when(mockDatabase.containsGame('A')).thenReturn(true);
      expect(await server.joinGame('A', Int64.ONE), isNull);
    });

    test('should return a game with a new user for a partially full game', () {
      var game = server.createGame();
      var onePlayerGame = server.joinGame(game.id, Int64.ONE);
      var twoPlayerGame = server.joinGame(game.id, Int64.TWO);

      expect(onePlayerGame.userIds.length, 1);
      expect(onePlayerGame.userIds.contains(Int64.ONE), isTrue);

      expect(twoPlayerGame.userIds, unorderedEquals([Int64.ONE, Int64.TWO]));
    });

    test('should return the same game if it is full', () {
      var game = server.createGame();
      server..joinGame(game.id, Int64.ONE)..joinGame(game.id, Int64.TWO);
      var joinFailedGame = server.joinGame(game.id, new Int64(3));

      expect(joinFailedGame.userIds, unorderedEquals([Int64.ONE, Int64.TWO]));
    });
  });

  group('updateGameState', () {
    test('should return a new state if the change is valid', () {
      var game = server.createGame();
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      expect(server.updateGameState(game.id, newState), newState);
    });

    test('should return original state if the new state has >1 additions', () {
      var game = server.createGame();
      var originalState = server.getGameState(game.id);
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.x, Space.empty, Space.empty]
      ]);

      expect(server.updateGameState(game.id, newState), originalState);
    });

    test('should return original state if the new state has any deletions', () {
      var game = server.createGame();
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      expect(server.updateGameState(game.id, newState), newState);
      expect(server.updateGameState(game.id, startState), newState);
    });

    test(
        'should return original state if the new state has any '
        'substitutions', () {
      var game = server.createGame();
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      var substituteState = new Board.fromSpaces([
        [Space.o, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      expect(server.updateGameState(game.id, newState), newState);
      expect(server.updateGameState(game.id, substituteState), newState);
    });
  });

  group('joinGame', () {
    test(
        'should complete with an erroneous GameMessage if the user is '
        'invalid.', () async {
      commonSetUp(validUsers: [Int64.ONE]);
      var gameId = (await server.createGame()).game.id;
      var message = await server.joinGame(gameId, Int64.TWO);

      expect(message.game, isNull);
      expect(message.errors.isNotEmpty, isTrue);
    });

    test(
        'should complete with an erroneous GameMessage if the game '
        'doesn\'t exist', () async {
      commonSetUp(validUsers: [Int64.ONE]);
      var message = await server.joinGame(Int64.ZERO, Int64.ONE);
      expect(message.game, isNull);
      expect(message.errors.isEmpty, isFalse);
    });

    test('should complete with an erroneous GameMessage if the game is full',
        () async {
      commonSetUp(validUsers: [
        Int64.ZERO,
        Int64.ONE,
        Int64.TWO,
      ]);

      var gameId = (await server.createGame()).game.id;
      var onePlayerMsg = await server.joinGame(gameId, Int64.ZERO);
      var twoPlayersMsg = await server.joinGame(gameId, Int64.ONE);
      var threePlayersMsg = await server.joinGame(gameId, Int64.TWO);
      var userIds = onePlayerMsg.game.userIds;

      expect(userIds, [Int64.ZERO]);

      userIds = twoPlayersMsg.game.userIds;
      expect(userIds, unorderedEquals([Int64.ZERO, Int64.ONE]));

      userIds = threePlayersMsg.game.userIds;
      expect(userIds, unorderedEquals([Int64.ZERO, Int64.ONE]));
      expect(threePlayersMsg.errors.isEmpty, isFalse);
    });

    test(
        'should complete with a GameMessage containing the joined game if '
        'the user joined sucessfully', () async {
      commonSetUp(validUsers: [
        Int64.ZERO,
        Int64.ONE,
      ]);

      var gameId = (await server.createGame()).game.id;
      var message = (await Future.wait([
        server.joinGame(gameId, Int64.ZERO),
        server.joinGame(gameId, Int64.ONE),
      ]))
          .last;
      var userIds = message.game.userIds;
      expect(userIds, unorderedEquals([Int64.ZERO, Int64.ONE]));
    });
  });

  group('updateGameState', () {
    test(
        'should complete with a StateMessage containing the updated state '
        'if the change is valid.', () async {
      commonSetUp();
      var gameId = (await server.createGame()).game.id;
      var newGameState =
          await server.updateGameState(gameId, new Board.fromSpaces(startMove));
      expect(newGameState.errors, isEmpty);
    });

    test(
        'should complete with an erroneous StateMessage if the change is '
        'invalid.', () async {
      commonSetUp();
      var gameId = (await server.createGame()).game.id;
      var originalGameState = (await server.updateGameState(
              gameId, new Board.fromSpaces(startMove)))
          .state;
      var newGameMessage = (await server.updateGameState(
          gameId,
          new Board.fromSpaces([
            [Space.empty, Space.empty, Space.empty],
            [Space.empty, Space.empty, Space.empty],
            [Space.empty, Space.empty, Space.empty],
          ])));
      expect(newGameMessage.errors, isNotEmpty);
      expect(originalGameState, newGameMessage.state);
    });
    */
  });
}

class MockTicTacToeDatabase extends Mock implements TicTacToeDatabase {}

class MockFile extends Mock implements File {}
