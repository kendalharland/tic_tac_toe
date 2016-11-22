import 'dart:convert';

import 'package:tic_tac_toe.state/state.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

abstract class Entity {
  Object toJson();
}

class Game implements Entity {
  final String name;
  final List<Player> players;
  final Board state;

  Game(this.name, this.state, this.players);

  factory Game.fromJson(Map<String, Object> json) => new Game(
      json['name'],
      new Board.fromJson(json['state'] as List<List<String>>),
      new List.from((json['players'] as List<Map<String, Object>>)
          .map((player) => new Player.fromJson(player))));

  factory Game.fromString(String json) =>
      new Game.fromJson(JSON.decode(json) as Map<String, Object>);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'Game ' + JSON.encode(toJson());

  @override
  bool operator ==(Object other) =>
      other is Game &&
      other.name == name &&
      other.state == state &&
      const ListEquality().equals(players, other.players);

  @override
  Map<String, Object> toJson() => {
        'name': name,
        'state': state.toJson(),
        'players': players.map((player) => player.toJson()).toList()
      };
}

class User implements Entity {
  final Int64 id;
  final String name;

  User(this.id, this.name);

  factory User.fromJson(Map<String, Object> json) =>
      new User(new Int64(json['id']), json['name']);

  factory User.fromString(String json) =>
      new User.fromJson(JSON.decode(json) as Map<String, Object>);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => 'User ' + JSON.encode(toJson());

  @override
  bool operator ==(Object other) =>
      other is User && other.id == id && other.name == name;

  @override
  Map<String, Object> toJson() => {'id': id.toInt(), 'name': name};
}

class Player implements Entity {
  final User user;
  final Space turn;

  Player(this.user, this.turn);

  factory Player.fromJson(Map<String, Object> json) => new Player(
      new User.fromJson(json['user'] as Map<String, Object>),
      _decodeSpace(json['turn']));

  static String _encodeSpace(Space space) {
    switch (space) {
      case Space.o:
        return 'o';
      case Space.x:
        return 'x';
      default:
        return '';
    }
  }

  static Space _decodeSpace(String space) {
    switch (space) {
      case 'o':
        return Space.o;
      case 'x':
        return Space.x;
      default:
        return Space.empty;
    }
  }

  @override
  Map<String, Object> toJson() =>
      {'user': user.toJson(), 'turn': _encodeSpace(turn)};
}
