import 'dart:async';
import 'dart:io';

import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';
import 'src/database_test.dart';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('$MemoryDatabase', () {
    MemoryDatabase<String, String> database;
    MockFile mockFile;

    Future<Database<String, String>> setup() async {
      mockFile = new MockFile();
      var serializer = new MockSerializer();
      when(mockFile.readAsLinesSync()).thenReturn([]);
      return new MemoryDatabase<String, String>(mockFile, serializer, serializer);
    }

    testDatabase(setup, () async {});

    test('saveOnDisk should write all contents to disk', () async {
      database = await setup();
      var contents = '';

      when(mockFile.writeAsStringSync(any)).thenAnswer((Invocation inv) {
        contents = inv.positionalArguments.first as String;
      });

      await database.insert('A', 'B');
      await database.insert('C', 'D');
      await database.writeToFile();
      expect(contents, contains('A'));
      expect(contents, contains('B'));
      expect(contents, contains('C'));
      expect(contents, contains('D'));
    });
  });
}

class MockFile extends Mock implements File {}

class MockSerializer extends Mock implements Serializer<String> {
  @override
  String serialize(String _) => _;

  @override
  String deserialize(String _) => _;
}
