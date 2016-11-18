import 'dart:convert';

import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.state/state.dart';

import 'package:fixnum/fixnum.dart';

/// An object that serializes instances of [T] to and from Strings.
abstract class Serializer<T> {
  /// Converts [object] to an instance of S.
  String serialize(T object);

  /// Converts [object] to an instance of D.
  T deserialize(String object);
}

/// Serializes [Iterable<T>] instances.
///
/// [Iterable]s are comma-delimited during serialization, so attempting to
/// serialize a collection of strings containing commas will result in
/// improper deserialization.
class IterableSerializer<T> implements Serializer<Iterable<T>> {
  final Serializer<T> _delegate;

  const IterableSerializer(this._delegate);

  @override
  String serialize(Iterable<T> iterable) =>
      '(' + iterable.map(_delegate.serialize).join(',') + ')';

  @override
  Iterable<T> deserialize(String iterable) {
    iterable = iterable.substring(1, iterable.length - 2);
    return iterable.split(',').map(_delegate.deserialize);
  }
}

class Int64Serializer implements Serializer<Int64> {
  const Int64Serializer();

  @override
  String serialize(Int64 number) => number.toString();

  @override
  Int64 deserialize(String number) => new Int64.fromBytes(number.codeUnits);
}

class UserSerializer implements Serializer<User> {
  static const _decoder = const JsonDecoder();

  const UserSerializer();

  @override
  String serialize(User user) => user.toString();

  @override
  User deserialize(String user) =>
      new User.fromJson(_decoder.convert(user) as Map<String, Object>);
}

class BoardSerializer implements Serializer<Board> {
  static const _decoder = const JsonDecoder();

  const BoardSerializer();

  @override
  String serialize(Board board) => board.toString();

  @override
  Board deserialize(String board) =>
      new Board.fromJson(_decoder.convert(board) as List<List<String>>);
}

class GameSerializer implements Serializer<Game> {
  static const _decoder = const JsonDecoder();

  const GameSerializer();

  @override
  String serialize(Game game) => game.toString();

  @override
  Game deserialize(String game) =>
      new Game.fromJson(_decoder.convert(game) as Map<String, Object>);
}
