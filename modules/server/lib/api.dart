import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:tic_tac_toe.state/state.dart';
import 'package:collection/collection.dart';

// TODO(kharland): Delete when database exists.
final JONAH = new User(Int64.ONE, "Jonah");
final MATAN = new User(Int64.TWO, "Matan");
final KENDAL = new User(new Int64(3), "Kendal");
final HARRY = new User(new Int64(4), "Harry");

abstract class Entity {
  Object toJson();
}

class Message extends Entity {
  final List<String> errors;

  Message._([Iterable<String> errors = const []])
      : errors = new List<String>.unmodifiable(errors);
}

class Game implements Entity {
  final Int64 id;
  final List<Int64> userIds;

  Game(this.id, Iterable<Int64> userIds)
      : userIds = new List<Int64>.unmodifiable(userIds);

  factory Game.fromJson(Map<String, Object> json) => new Game(
      new Int64(json['id']), json['userIds'].map((id) => new Int64(id)));

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'Game ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is Game &&
      other.id == id &&
      const ListEquality().equals(userIds, other.userIds);

  @override
  Map<String, Object> toJson() =>
      {'id': id.toInt(), 'userIds': userIds.map((id) => id.toInt()).toList()};
}

class User implements Entity {
  final Int64 id;
  final String name;

  User(this.id, this.name);

  factory User.fromJson(Map<String, Object> json) =>
      new User(new Int64(json['id']), json['name']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'User ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.name == name;

  @override
  Map<String, Object> toJson() => {'id': id.toInt(), 'name': name};
}

class StateMessage extends Message {
  final Board state;

  StateMessage(this.state, Iterable<String> errors) : super._(errors);

  factory StateMessage.fromJson(Map<String, Object> json) =>
      new StateMessage(new Board.fromJson(json['state']), json['errors']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'StateMessage ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is StateMessage &&
      other.state == state &&
      const ListEquality().equals(errors, other.errors);

  @override
  Map<String, Object> toJson() => {'state': state?.toJson(), 'errors': errors};
}

class GameMessage extends Message {
  final Game game;

  GameMessage(this.game, Iterable<String> errors) : super._(errors);

  factory GameMessage.fromJson(Map<String, Object> json) =>
      new GameMessage(new Game.fromJson(json['game']), json['errors']);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'GameMessage ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is GameMessage &&
      other.game == game &&
      const ListEquality().equals(errors, other.errors);

  @override
  Map<String, Object> toJson() => {'game': game?.toJson(), 'errors': errors};
}

abstract class _Json {
  static const _jsonEncoder = const JsonEncoder.withIndent('  ', _toString);

  static String _toString(Object o) => o.toString();

  static String convert(Object o) => _jsonEncoder.convert(o);
}
