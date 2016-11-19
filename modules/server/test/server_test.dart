import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/testing/testing_database.dart';
import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.net/src/messages.dart';
import 'package:tic_tac_toe.server/src/server.dart';
import 'package:tic_tac_toe.state/state.dart';

void main() {
  Server server;
  TestingDatabase<Int64, User> testUserDatabase;
  TestingDatabase<String, Game> testGameDatabase;

  final startState = new Board.fromSpaces([
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty]
  ]);

  group('$Server', () {
    setUp(() {
      testUserDatabase = new TestingDatabase<Int64, User>();
      testGameDatabase = new TestingDatabase<String, Game>();
      server = new Server.withDatabases(
          userDatabase: testUserDatabase, gameDatabase: testGameDatabase);
    });

    group('createGame', () {
      test('should complete with an error if a game with the given name exists',
          () async {
        testGameDatabase.entries = {'A': new Game('A', new Board(), const [])};
        expect((await server.createGame('A')).message, isNotEmpty);
      });

      test('should complete with a GameMessage containing a new game',
          () async {
        var message = await server.createGame('A');
        expect(message, new isInstanceOf<GameMessage>());
        expect(message.game.userIds, isEmpty);
        expect(message.game.state, startState);
      });
    });

    group('joinGame', () {
      test('should complete with an error if the game does not exist',
          () async {
        var message = await server.joinGame('A', Int64.ONE);
        expect(message.game, isNull);
        expect(message.message, isNotEmpty);
      });

      test('should return a game with a new user for a partially full game',
          () async {
        var game = (await server.createGame('A')).game;
        var userA = new User(Int64.ONE, '');
        var userB = new User(Int64.TWO, '');
        testUserDatabase.entries = <Int64, User>{
          userA.id: userA,
          userB.id: userB
        };

        var onePlayerGame = (await server.joinGame(game.name, userA.id)).game;
        var twoPlayerGame = (await server.joinGame(game.name, userB.id)).game;

        expect(onePlayerGame.userIds, unorderedEquals([Int64.ONE]));
        expect(twoPlayerGame.userIds, unorderedEquals([Int64.ONE, Int64.TWO]));
      });

      test('should fail to join a game if it is full', () async {
        var game = (await server.createGame('A')).game;
        var userA = new User(Int64.ONE, '');
        var userB = new User(Int64.TWO, '');
        testUserDatabase.entries = <Int64, User>{
          userA.id: userA,
          userB.id: userB
        };

        await server.joinGame(game.name, userA.id);
        await server.joinGame(game.name, userB.id);
        var message = await server.joinGame(game.name, new Int64(3));

        expect(message.game, isNull);
        expect(message.message, isNotEmpty);
      });

      test('should fail if the user is already in the specified game',
          () async {
        var game = (await server.createGame('A')).game;
        var userA = new User(Int64.ONE, '');
        testUserDatabase.entries = <Int64, User>{
          userA.id: userA,
        };

        await server.joinGame(game.name, userA.id);
        var message = await server.joinGame(game.name, userA.id);

        expect(message.game, isNull);
        expect(message.message, isNotEmpty);
      });
    });

    group('setGameState', () {
      Game game;

      setUp(() async {
        game = (await server.createGame('A')).game;
      });

      test('should update a new state if the change is valid', () async {
        var newState = new Board.fromSpaces([
          [Space.x, Space.empty, Space.empty],
          [Space.empty, Space.empty, Space.empty],
          [Space.empty, Space.empty, Space.empty]
        ]);

        expect(
            (await server.setGameState(game.name, newState)).state, newState);
      });

      test('should fail with error if the new state has multiple additions',
          () async {
        var originalState = server.getGameState(game.name);
        var newState = new Board.fromSpaces([
          [Space.x, Space.empty, Space.empty],
          [Space.empty, Space.empty, Space.empty],
          [Space.x, Space.empty, Space.empty]
        ]);

        expect((await server.setGameState(game.name, newState)).state, isNull);
        expect((await server.getGameState(game.name)).state, originalState);
      });

      test('should return original state if the new state has any deletions',
          () {
        var newState = new Board.fromSpaces([
          [Space.x, Space.empty, Space.empty],
          [Space.empty, Space.empty, Space.empty],
          [Space.empty, Space.empty, Space.empty]
        ]);

        expect(server.setGameState(game.name, newState), newState);
        expect(server.setGameState(game.name, startState), newState);
      });

      test(
          'should return original state if the new state has any '
          'substitutions', () {
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

        expect(server.setGameState(game.name, newState), newState);
        expect(server.setGameState(game.name, substituteState), newState);
      });
    });
  });
}

class MockDatabase<K, V> extends Mock implements Database<K, V> {}
