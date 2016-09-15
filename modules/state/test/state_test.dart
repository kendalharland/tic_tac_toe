import 'package:tic_tac_toe.state/state.dart';
import 'package:test/test.dart';

void main() {
  test('should create an empty board', () {
    expect(new Board().isBlank(), isTrue);
  });

  test('should have no winner initially', () {
    expect(new Board().isOver(), isFalse);
  });

  test('should initially be turn x', () {
    expect(new Board().getTurn(), Space.x);
  });

  test('should then become turn o', () {
    expect(new Board().move(0, 0).getTurn(), Space.o);
  });

  test('should have a winner eventually', () {
    var board = new Board.fromSpaces([
      [Space.x, Space.x, Space.x],
      [Space.o, Space.o, Space.x],
      [Space.x, Space.o, Space.o],
    ]);
    expect(board.isBlank(), isFalse);
    expect(board.isOver(), isTrue);
    expect(board.getWinner(), Space.x);
  });
}
