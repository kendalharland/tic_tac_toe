import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:tic_tac_toe.net/net.dart';
import 'package:tic_tac_toe.server/src/server.dart';
import 'package:tic_tac_toe.state/state.dart';
import 'package:express/express.dart';
import 'package:fixnum/fixnum.dart';

typedef Future RouteHandler(HttpContext ctx);

// TODO(kjharland): Validate URL arguments to prevent crashing when invalid
// types are parsed.
class Server {
  final _express = new Express();
  final _server;

  /// TODO(kjharland): fix routes.
  Server([String databaseRoot = '.'])
      : _server = new TicTacToeDatabase.withDatabaseRoot(databaseRoot) {
    _express
      ..post('/user/:id/:name', (HttpContext ctx) async {
        ctx.sendJson((await _server.addUser(
            new User(Int64.parseInt(ctx.params['id']), ctx.params['name'])))
            .toJson());
        ctx.end();
      })
      ..get('/user/:id', (HttpContext ctx) async {
        ctx.sendJson(
            (await _server.getUser(Int64.parseInt(ctx.params['id']))).toJson());
        ctx.end();
      })
      ..get('/game/:name', (HttpContext ctx) async {
        ctx.sendJson((await _server.getGame(ctx.params['name'])).toJson());
        ctx.end();
      })
      ..post('/game/:name', (HttpContext ctx) async {
        ctx.sendJson((await _server.createGame(ctx.params['name'])).toJson());
        ctx.end();
      })
      ..get('/game/join/:gameName/:userId', (HttpContext ctx) async {
        ctx.sendJson((await _server.joinGame(
            ctx.params['gameName'], Int64.parseInt(ctx.params['userId'])))
            .toJson());
        ctx.end();
      })
      ..put('/game/state/:gameName/:state', (HttpContext ctx) async {
        ctx.sendJson((await _server.setGameState(
            ctx.params['gameName'],
            new Board.fromJson(
                JSON.decode(Uri.decodeFull(ctx.params['state']))
                as List<List<String>>)))
            .toJson());
        ctx.end();
      });
  }

  Future<HttpServer> listen(String hostname, int port) =>
      _express.listen(hostname, port);
}
