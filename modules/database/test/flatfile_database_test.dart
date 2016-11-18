import 'dart:io';

import 'package:tic_tac_toe.database/database.dart';
import 'src/database_test.dart';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('$FlatFileDatabase', () {
    FlatFileDatabase database;

    setUp(() {
      var file = new MockFile();
      when(file.readAsLinesSync()).thenReturn(['A', 'B', 'C']);
      database = new FlatFileDatabase(file, new Serializer.noop());
    });
    
    testDatabase(database);
  });
}

class MockFile extends Mock implements File {}
