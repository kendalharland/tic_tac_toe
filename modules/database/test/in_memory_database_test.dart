import 'dart:io';

import 'package:tic_tac_toe.database/database.dart';
import 'package:tic_tac_toe.database/serializer.dart';
import 'src/database_test.dart';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('$InMemoryDatabase', () {
    testDatabase(() async {
      var file = new MockFile();
      var serializer = new MockSerializer();
      when(file.readAsLinesSync()).thenReturn([]);
      return new InMemoryDatabase<String, String>(file, serializer, serializer);
    }, () async {});
  });
}

class MockFile extends Mock implements File {}

class MockSerializer extends Mock implements Serializer<String>{
  @override
  String serialize(String _) => _;

  @override
  String deserialize(String _) => _;
}