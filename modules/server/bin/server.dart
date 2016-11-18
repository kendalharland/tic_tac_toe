import 'package:tic_tac_toe.server/server.dart';

void main() {
  createDefaultServer().listen('localhost', 8080);
}
