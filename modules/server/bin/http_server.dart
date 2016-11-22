import 'package:tic_tac_toe.server/http_server.dart';

void main() {
  new Server('.').listen('localhost', 8080);
}
