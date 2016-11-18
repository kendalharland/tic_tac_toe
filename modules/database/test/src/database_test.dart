@TestOn('vm')

import 'package:test/test.dart';

void testDatabase(Database<String, String> database) {
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
    await database.remove('B');
    expect(await database.get('A'), isNull);
  });
}