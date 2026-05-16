import 'dart:convert';
import 'package:shelf/shelf.dart';

final _json = {'content-type': 'application/json'};

/// Placeholder: Instagram API integration requires OAuth tokens.
/// Returns mock data for now. Wire up real Instagram Graph API in production.
Future<Response> handleInstagramRecent(Request request) async {
  return Response.ok(jsonEncode({
    'media': [],
    'message': 'Instagram integration not configured. Add your Instagram Graph API token.',
  }), headers: _json);
}

Future<Response> handleFetchReelLikes(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final url = body['url'] as String? ?? '';

  if (url.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'URL required'}), headers: _json);
  }

  // Placeholder response — real implementation would scrape or use API
  return Response.ok(jsonEncode({
    'url': url,
    'likes': 0,
    'views': 0,
    'message': 'Instagram scraping not configured. Enter stats manually.',
  }), headers: _json);
}

Future<Response> handleInstagramHandleStats(Request request) async {
  final handle = request.requestedUri.queryParameters['handle'] ?? '';

  if (handle.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'handle required'}), headers: _json);
  }

  // Placeholder — real implementation would use Instagram Basic Display API
  return Response.ok(jsonEncode({
    'handle': handle,
    'followers': 0,
    'avgLikes': 0,
    'lastPostLikes': 0,
    'message': 'Instagram handle stats require Graph API configuration.',
  }), headers: _json);
}
