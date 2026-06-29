import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:args/args.dart';
import 'package:rawby_server/router.dart';
import 'package:rawby_server/store.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()..addOption('port', abbr: 'p', defaultsTo: '8080');
  final result = parser.parse(args);
  final port = int.parse(Platform.environment['PORT'] ?? result['port'] as String);

  // Initialize MongoDB connection
  await Store.instance.initialize();

  final app = buildRouter();

  // Serve the built React SPA (committed under server/web) so the whole app is
  // reachable at the same origin as the API. The API router runs first; unknown
  // paths fall through to static files, and unknown GET routes fall back to
  // index.html for client-side routing.
  Handler rootHandler = app;
  if (Directory('web').existsSync()) {
    final staticHandler = createStaticHandler('web', defaultDocument: 'index.html');
    final indexFile = File('web/index.html');
    Future<Response> spaFallback(Request r) async {
      if (r.method == 'GET' && !r.url.path.startsWith('api/') && indexFile.existsSync()) {
        return Response.ok(indexFile.readAsBytesSync(),
            headers: {'content-type': 'text/html; charset=utf-8'});
      }
      return Response.notFound('Not found');
    }
    rootHandler = Cascade().add(app).add(staticHandler).add(spaFallback).handler;
    print('  Serving SPA from ./web');
  }

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, PUT, PATCH, HEAD, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Admin-Secret, Accept',
        'Access-Control-Max-Age': '86400',
      }))
      .addHandler(rootHandler);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ RAWBY Server running on http://${server.address.host}:${server.port}');

  _startKeepAlive();
}

/// Render's free tier spins the instance down after ~15 min with no inbound
/// traffic, causing a slow cold start on the next request. Pinging our own
/// public URL (RENDER_EXTERNAL_URL, injected by Render) every 10 min keeps the
/// instance warm. No-op locally where the env var is absent.
void _startKeepAlive() {
  final base = Platform.environment['RENDER_EXTERNAL_URL'];
  if (base == null || base.isEmpty) return;
  final url = Uri.parse('$base/api/health');
  Timer.periodic(const Duration(minutes: 10), (_) async {
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 20));
      print('🔄 keep-alive ${res.statusCode}');
    } catch (e) {
      print('keep-alive failed: $e');
    }
  });
}
