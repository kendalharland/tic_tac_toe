import 'dart:async';
@TestOn('vm')
import 'package:test/test.dart';
import 'package:tic_tac_toe.database/database.dart';

/// Factory for [Database] instances.
typedef Future<Database<String, String>> DatabaseProvider();

/// Common tests for [Database].
void testDatabase(DatabaseProvider setup, Future<Null> teardown()) {
  Database<String, String> database;

  group('', () {
    setUp(() async {
      database = await setup();
    });

    tearDown(teardown);

    test('keys should return the keys in the database', () async {
      await database.insert('A', 'B');
      await database.insert('C', 'D');
      expect(database.keys, unorderedEquals(['A', 'C']));

      await database.remove('A');
      expect(database.keys, unorderedEquals(['C']));
    });

    test('insert should insert a value for some key', () async {
      await database.insert('A', 'B');
      expect(await database.get('A'), 'B');
    });

    test('update should update a value for some key', () async {
      await database.insert('A', 'B');
      await database.update('A', 'C');
      expect(await database.get('A'), 'C');
    });

    test('get should return the value associated with a key', () async {
      await database.insert('A', 'B');
      expect(await database.get('A'), 'B');
      expect(await database.get('B'), isNull);
    });

    test('remove should remove the value associated with a key', () async {
      await database.insert('A', 'B');
      await database.remove('A');
      expect(await database.get('A'), isNull);
    });

    test('where should return all items that pass the filter', () async {
      await database.insert('A', 'aa');
      await database.insert('B', 'bb');
      await database.insert('C', 'c');
      expect(await database.where((_, String value) => value.length > 1),
          unorderedEquals(['aa', 'bb']));
    });
  });
}
