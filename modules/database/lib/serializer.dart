import 'dart:convert';

import 'package:tic_tac_toe.server/api.dart';

abstract class Serializer<T> {
  factory Serializer.json() => new _JsonSerializer();

  String serialize(T object);

  T deserialize(String object);
}

class UserSerializer implements Serializer<User> {
  static const _decoder = const JsonDecoder();

  String serializer(User user) => user.toString();

  User deserialize(String user) => new User.from(_decoder.decode(user));
}

class BoardSerializer implements Serializer<Board> {
  static const _decoder = const JsonDecoder();

  String serializer(Board board) => board.toString();

  Board deserialize(String board) => new User.from(_decoder.decode(board));
}
