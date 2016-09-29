import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:tic_tac_toe.server/src/controller.dart';
import 'package:tic_tac_toe.server/api.dart';
import 'package:tic_tac_toe.state/state.dart';
import 'package:express/express.dart';
import 'package:fixnum/fixnum.dart';

typedef Future RouteHandler(HttpContext ctx);

Server createDefaultServer() {
  var controller = new Controller();
  return new Server(
      controller,
      new Express()
        ..get('/game/create', (HttpContext ctx) async {
          var message = await controller.createGame();
          ctx.sendJson(message.toJson());
          ctx.end();
        })
        ..get('/game/join/:gameId/:userId', (HttpContext ctx) async {
          var gameId = Int64.parseInt(ctx.params['gameId']);
          var userId = Int64.parseInt(ctx.params['userId']);
          var message = await controller.joinGame(gameId, userId);
          ctx.sendJson(message.toJson());
        })
        ..get('/game/state/get/:gameId', (HttpContext ctx) async {
          var gameId = Int64.parseInt(ctx.params['gameId']);
          var message = await controller.getGameState(gameId);
          ctx.sendJson(message.toJson());
        })
        ..get('/game/state/update/:gameId/:state', (HttpContext ctx) async {
          var gameId = Int64.parseInt(ctx.params['gameId']);
          var newState = new Board.fromJson(
              JSON.decode(Uri.decodeFull(ctx.params['state'])));
          var message = await controller.updateGameState(gameId, newState);
          // print(message);
          ctx.sendJson(message.toJson());
        }));
}

class Server {
  final Controller _controller;
  final Express _express;

  Server(this._controller, [this._express]);

  void registerGETHandler(String route, RouteHandler handler) {
    _express ?? new Express();
    _express.get(route, handler);
  }

  Future<HttpServer> listen(String hostname, int port) =>
      _express.listen(hostname, port);
}
