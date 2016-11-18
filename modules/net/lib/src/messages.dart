import 'package:collection/collection.dart';
import 'package:tic_tac_toe.net/src/entities.dart';
import 'package:tic_tac_toe.state/state.dart';

abstract class Message {
  final List<String> errors;

  Message._([Iterable<String> errors = const []])
      : errors = new List<String>.unmodifiable(errors);

  /// Converts this message to a JSON friendly format.
  Object toJson();
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

  GameMessage(this.game, [Iterable<String> errors = const []])
      : super._(errors);

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
