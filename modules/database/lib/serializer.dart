import 'dart:convert';

import 'package:tic_tac_toe.net/net.dart';

import 'package:fixnum/fixnum.dart';

/// An object that serializes instances of [T] to and from Strings.
abstract class Serializer<T> {
  /// Converts [object] to an instance of S.
  String serialize(T object);

  /// Converts [object] to an instance of D.
  T deserialize(String object);
}

/// A no-op [Serializer] implementation.
class StringSerializer implements Serializer<String> {
  @override
  String serialize(String object) => object;

  @override
  String deserialize(String object) => object;
}

class Int64Serializer implements Serializer<Int64> {
  const Int64Serializer();

  @override
  String serialize(Int64 number) => number.toString();

  @override
  Int64 deserialize(String number) => Int64.parseInt(number);
}

class UserSerializer implements Serializer<User> {
  const UserSerializer();

  @override
  String serialize(User user) => JSON.encode(user.toJson());

  @override
  User deserialize(String user) =>
      new User.fromJson(JSON.decode(user) as Map<String, Object>);
}

class GameSerializer implements Serializer<Game> {
  const GameSerializer();

  @override
  String serialize(Game game) => JSON.encode(game.toJson());

  @override
  Game deserialize(String game) =>
      new Game.fromJson(JSON.decode(game) as Map<String, Object>);
}
