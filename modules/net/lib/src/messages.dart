import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:tic_tac_toe.net/src/entities.dart';
import 'package:tic_tac_toe.state/state.dart';

abstract class Message {
  final String message;

  Message._([this.message = '']);

  /// Converts this message to a JSON friendly format.
  Object toJson();
}

class StateMessage extends Message {
  final Board state;

  StateMessage(this.state, [String message = '']) : super._(message);

  factory StateMessage.fromJson(Map<String, Object> json) => new StateMessage(
      new Board.fromJson(json['state'] as List<List<String>>), json['message']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'StateMessage ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is StateMessage && other.state == state && message == other.message;

  @override
  Map<String, Object> toJson() =>
      {'state': state?.toJson(), 'message': message};
}

class GameMessage extends Message {
  final Game game;

  GameMessage(this.game, [String message = '']) : super._(message);

  factory GameMessage.fromJson(Map<String, Object> json) => new GameMessage(
      new Game.fromJson(json['game'] as Map<String, Object>), json['message']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'GameMessage ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is GameMessage && other.game == game && message == other.message;

  @override
  Map<String, Object> toJson() => {'game': game?.toJson(), 'message': message};
}

class UserMessage extends Message {
  static final _listEq = const IterableEquality().equals;
  final Iterable<User> users;

  UserMessage(this.users, [String message = '']) : super._(message);

  factory UserMessage.fromJson(Map<String, Object> json) => new UserMessage(
      (json['users'] as List<Map<String, Object>>)
          .map((jsonUser) => new User.fromJson(jsonUser)),
      json['message']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'UserMessage ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is UserMessage &&
      message == other.message &&
      _listEq(users, other.users);

  @override
  Map<String, Object> toJson() =>
      {'users': users.map((u) => u.toJson()), 'message': message};
}

abstract class _Json {
  static const _jsonEncoder = const JsonEncoder.withIndent('  ', _toString);

  static String _toString(Object o) => o.toString();

  static String convert(Object o) => _jsonEncoder.convert(o);
}
