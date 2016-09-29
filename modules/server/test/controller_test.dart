import 'dart:async';

import 'package:tic_tac_toe.state/state.dart';
import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.server/src/controller.dart';
import 'package:tic_tac_toe.server/src/game_service.dart';
import 'package:tic_tac_toe.server/src/auth_service.dart';

import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  Controller controller;
  MockAuthService mockAuthService;

  final validInitialMove = [
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.empty],
    [Space.empty, Space.empty, Space.x],
  ];

  void commonSetUp({List<Int64> validUsers: const []}) {
    mockAuthService = new MockAuthService(validUsers);
    controller = new Controller.fromServices(new GameService(), mockAuthService);
  }

  // In case a test passes because client forgot to call `commonSetUp`.
  tearDown(() {
    mockAuthService = null;
    controller = null;
  });

  test('createGame should complete with a GameMessage.', () async {
    commonSetUp();
    var message = await controller.createGame();
    expect(message, new isInstanceOf<GameMessage>());
    expect(message.game, new isInstanceOf<Game>());
  });

  group('joinGame', () {
    test(
        'should complete with an erroneous GameMessage if the user is '
        'invalid.', () async {
      commonSetUp(validUsers: [Int64.ONE]);
      var gameId = (await controller.createGame()).game.id;
      var message = await controller.joinGame(gameId, Int64.TWO);

      expect(message.game, isNull);
      expect(message.errors.isNotEmpty, isTrue);
    });

    test(
        'should complete with an erroneous GameMessage if the game '
        'doesn\'t exist', () async {
      commonSetUp(validUsers: [Int64.ONE]);
      var message = await controller.joinGame(Int64.ZERO, Int64.ONE);
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

      var gameId = (await controller.createGame()).game.id;
      var onePlayerMsg = await controller.joinGame(gameId, Int64.ZERO);
      var twoPlayersMsg = await controller.joinGame(gameId, Int64.ONE);
      var threePlayersMsg = await controller.joinGame(gameId, Int64.TWO);
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

      var gameId = (await controller.createGame()).game.id;
      var message = (await Future.wait([
        controller.joinGame(gameId, Int64.ZERO),
        controller.joinGame(gameId, Int64.ONE),
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
      var gameId = (await controller.createGame()).game.id;
      var newGameState = await controller.updateGameState(
          gameId, new Board.fromSpaces(validInitialMove));
      expect(newGameState.errors, isEmpty);
    });

    test(
        'should complete with an erroneous StateMessage if the change is '
        'invalid.', () async {
      commonSetUp();
      var gameId = (await controller.createGame()).game.id;
      var originalGameState = (await controller.updateGameState(
              gameId, new Board.fromSpaces(validInitialMove)))
          .state;
      var newGameMessage = (await controller.updateGameState(
          gameId,
          new Board.fromSpaces([
            [Space.empty, Space.empty, Space.empty],
            [Space.empty, Space.empty, Space.empty],
            [Space.empty, Space.empty, Space.empty],
          ])));
      expect(newGameMessage.errors, isNotEmpty);
      expect(originalGameState, newGameMessage.state);
    });
  });
}

class MockAuthService extends Mock implements AuthService {
  final List<Int64> _validUsers;

  MockAuthService(this._validUsers);

  @override
  isUserValid(Int64 userId) => _validUsers.contains(userId);
}
