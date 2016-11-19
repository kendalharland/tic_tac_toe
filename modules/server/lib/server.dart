import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.server/src/database.dart';
import 'package:tic_tac_toe.server/src/server_impl.dart';
import 'package:tic_tac_toe.state/state.dart';
import 'package:express/express.dart';
import 'package:fixnum/fixnum.dart';

typedef Future RouteHandler(HttpContext ctx);

// TODO(kjharland): Validate URL arguments to prevent crashing when invalid
// types are parsed.
Server createServer({String databaseRoot: '.'}) {
  var server = new Server(databaseRoot);
  return new Server(new Express()
    ..get('/game/create/:name', (HttpContext ctx) async {
      ctx.sendJson((await server.createGame(ctx.params['name'])).toJson());
      ctx.end();
    })
    ..get('/game/join/:gameName/:userId', (HttpContext ctx) async {
      ctx.sendJson((await server.joinGame(
              ctx.params['gameName'], Int64.parseInt(ctx.params['userId'])))
          .toJson());
      ctx.end();
    })
    ..get('/game/state/update/:gameName/:state', (HttpContext ctx) async {
      var game = await server.updateGameState(
          ctx.params['gameName'],
          new Board.fromJson(JSON.decode(Uri.decodeFull(ctx.params['state']))
              as List<List<String>>));
      ctx.sendJson(new GameMessage(
              game, game == null ? ['Could not update game state'] : [])
          .toJson());
      ctx.end();
    }));
}

class Server {
  final Express _express;

  Server([this._express]);

  void registerGETHandler(String route, RouteHandler handler) {
    _express ?? new Express();
    _express.get(route, handler);
  }

  Future<HttpServer> listen(String hostname, int port) =>
      _express.listen(hostname, port);
}
