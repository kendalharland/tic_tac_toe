import 'package:tic_tac_toe.state/state.dart';
import 'package:tic_tac_toe.server/src/game_service.dart';

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  GameService service;

  final startState = new Board.fromSpaces([
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty]
  ]);

  setUp(() {
    service = new GameService();
  });

  group('createGame', () {
    test('should create a new Game witout users', () {
      expect(service.createGame().userIds.isEmpty, isTrue);
    });

    test('should create a new Game all empty spaces', () {
      var game = service.createGame();
      expect(service.getGameState(game.id), startState);
    });
  });

  group('joinGame', () {
    test('should return null if the game does not exist', () {
      expect(service.joinGame(Int64.ONE, Int64.ONE), isNull);
    });

    test('should return a game with a new user for a partially full game', () {
      var game = service.createGame();
      var onePlayerGame = service.joinGame(game.id, Int64.ONE);
      var twoPlayerGame = service.joinGame(game.id, Int64.TWO);

      expect(onePlayerGame.userIds.length, 1);
      expect(onePlayerGame.userIds.contains(Int64.ONE), isTrue);

      expect(twoPlayerGame.userIds, unorderedEquals([Int64.ONE, Int64.TWO]));
    });

    test('should return the same game if it is full', () {
      var game = service.createGame();
      service..joinGame(game.id, Int64.ONE)..joinGame(game.id, Int64.TWO);
      var joinFailedGame = service.joinGame(game.id, new Int64(3));

      expect(joinFailedGame.userIds, unorderedEquals([Int64.ONE, Int64.TWO]));
    });
  });

  group('updateGameState', () {
    test('should return a new state if the change is valid', () {
      var game = service.createGame();
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      expect(service.updateGameState(game.id, newState), newState);
    });

    test('should return original state if the new state has >1 additions', () {
      var game = service.createGame();
      var originalState = service.getGameState(game.id);
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.x, Space.empty, Space.empty]
      ]);

      expect(service.updateGameState(game.id, newState), originalState);
    });

    test('should return original state if the new state has any deletions', () {
      var game = service.createGame();
      var newState = new Board.fromSpaces([
        [Space.x, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty],
        [Space.empty, Space.empty, Space.empty]
      ]);

      expect(service.updateGameState(game.id, newState), newState);
      expect(service.updateGameState(game.id, startState), newState);
    });

    test(
        'should return original state if the new state has any '
        'substitutions', () {
      var game = service.createGame();
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

      expect(service.updateGameState(game.id, newState), newState);
      expect(service.updateGameState(game.id, substituteState), newState);
    });
  });
}
