import 'dart:convert';

import 'package:tic_tac_toe.state/state.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

abstract class Entity {
  Object toJson();
}

class Game implements Entity {
  final String name;
  final List<Int64> userIds;
  final Board state;

  Game(this.name, this.state, Iterable<Int64> userIds)
      : userIds = new List<Int64>.unmodifiable(userIds);

  factory Game.fromJson(Map<String, Object> json) => new Game(
      json['name'],
      new Board.fromJson(json['state'] as List<List<String>>),
      new List.from((json['userIds'] as List<String>).map(Int64.parseInt)));

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'Game ' + _Json.convert(toJson());

  @override
  bool operator ==(Object other) =>
      other is Game &&
      other.name == name &&
      other.state == state &&
      const ListEquality().equals(userIds, other.userIds);

  @override
  Map<String, Object> toJson() => {
        'name': name,
        'state': state.toJson(),
        'userIds': userIds.map((id) => id.toInt()).toList()
      };
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

abstract class _Json {
  static const _jsonEncoder = const JsonEncoder.withIndent('  ', _toString);

  static String _toString(Object o) => o.toString();

  static String convert(Object o) => _jsonEncoder.convert(o);
}
