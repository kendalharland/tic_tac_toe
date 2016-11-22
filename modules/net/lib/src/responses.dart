import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:tic_tac_toe.net/src/entities.dart';
import 'package:tic_tac_toe.state/state.dart';

abstract class ServerResponse {
  final String message;
  final bool isError;

  ServerResponse._([this.message = '', this.isError = false]);

  /// Converts this message to a JSON friendly format.
  Object toJson();
}

class StateResponse extends ServerResponse {
  final Board state;

  StateResponse(this.state) : super._('', false);

  StateResponse.error(String message)
      : state = new Board(),
        super._(message, true);

  factory StateResponse.fromJson(Map<String, Object> json) {
    String message = json['message'];

    if (message.isNotEmpty) {
      return new StateResponse.error(message);
    }
    return new StateResponse(
        new Board.fromJson(json['state'] as List<List<String>>));
  }

  factory StateResponse.fromString(String json) =>
      new StateResponse.fromJson(JSON.decode(json) as Map<String, Object>);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'StateMessage ' + JSON.encode(toJson());

  @override
  bool operator ==(Object other) =>
      other is StateResponse &&
      other.state == state &&
      message == other.message;

  @override
  Map<String, Object> toJson() =>
      {'state': state?.toJson(), 'message': message};
}

class GameResponse extends ServerResponse {
  final Game game;

  GameResponse(this.game) : super._('', false);

  GameResponse.error(String message)
      : game = new Game('', new Board(), []),
        super._(message, true);

  factory GameResponse.fromJson(Map<String, Object> json) {
    String message = json['message'];

    if (message.isNotEmpty) {
      return new GameResponse.error(message);
    }
    return new GameResponse(
        new Game.fromJson(json['game'] as Map<String, Object>));
  }

  factory GameResponse.fromString(String json) =>
      new GameResponse.fromJson(JSON.decode(json) as Map<String, Object>);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'GameMessage ' + JSON.encode(toJson());

  @override
  bool operator ==(Object other) =>
      other is GameResponse && other.game == game && message == other.message;

  @override
  Map<String, Object> toJson() => {'game': game?.toJson(), 'message': message};
}

class UserResponse extends ServerResponse {
  static final _listEq = const IterableEquality().equals;
  final Iterable<User> users;

  UserResponse(this.users) : super._('', false);

  UserResponse.error(String message)
      : users = [],
        super._(message, true);

  factory UserResponse.fromJson(Map<String, Object> json) {
    String message = json['message'];

    if (message.isNotEmpty) {
      return new UserResponse.error(message);
    }
    return new UserResponse((json['users'] as List<Map<String, Object>>)
        .map((jsonUser) => new User.fromJson(jsonUser)));
  }

  factory UserResponse.fromString(String json) =>
      new UserResponse.fromJson(JSON.decode(json) as Map<String, Object>);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'UserMessage ' + JSON.encode(toJson());

  @override
  bool operator ==(Object other) =>
      other is UserResponse &&
      message == other.message &&
      _listEq(users, other.users);

  @override
  Map<String, Object> toJson() =>
      {'users': users.map((u) => u.toJson()).toList(), 'message': message};
}
