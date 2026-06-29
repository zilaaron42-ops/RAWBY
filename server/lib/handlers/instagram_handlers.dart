import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;

final _json = {'content-type': 'application/json'};
const _igBase = 'https://graph.instagram.com/v21.0';

String? get _token => Platform.environment['INSTAGRAM_ACCESS_TOKEN'];

/// GET /api/instagram-recent
/// Returns up to 12 recent media items from the connected Instagram account.
Future<Response> handleInstagramRecent(Request request) async {
  final token = _token;
  if (token == null || token.isEmpty) {
    return Response.ok(
      jsonEncode({'media': [], 'configured': false}),
      headers: _json,
    );
  }

  final uri = Uri.parse('$_igBase/me/media').replace(queryParameters: {
    'fields': 'id,caption,media_type,media_url,thumbnail_url,timestamp,like_count,comments_count,permalink',
    'limit': '12',
    'access_token': token,
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    return Response(res.statusCode,
        body: jsonEncode({'error': 'Instagram API error', 'detail': res.body}),
        headers: _json);
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final items = (data['data'] as List? ?? []).map((m) {
    final map = Map<String, dynamic>.from(m as Map);
    return map;
  }).toList();

  return Response.ok(jsonEncode({'media': items, 'configured': true}), headers: _json);
}

/// POST /api/fetch-reel-likes  { "mediaId": "..." } or { "url": "..." }
/// Fetches like_count / video_views for a specific reel via its media ID.
/// If URL provided, we first search recent media for a matching permalink.
Future<Response> handleFetchReelLikes(Request request) async {
  final token = _token;
  if (token == null || token.isEmpty) {
    return Response(503,
        body: jsonEncode({'error': 'Instagram not configured'}), headers: _json);
  }

  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  String? mediaId = body['mediaId'] as String?;
  final url = (body['url'] as String? ?? '').trim();

  // If no mediaId, try to find it by matching permalink in recent media
  if ((mediaId == null || mediaId.isEmpty) && url.isNotEmpty) {
    final shortcode = _extractShortcode(url);
    if (shortcode != null) {
      final listUri = Uri.parse('$_igBase/me/media').replace(queryParameters: {
        'fields': 'id,permalink',
        'limit': '50',
        'access_token': token,
      });
      final listRes = await http.get(listUri);
      if (listRes.statusCode == 200) {
        final items = (jsonDecode(listRes.body)['data'] as List? ?? []);
        for (final item in items) {
          final permalink = (item['permalink'] as String? ?? '');
          if (permalink.contains(shortcode)) {
            mediaId = item['id'] as String?;
            break;
          }
        }
      }
    }
  }

  if (mediaId == null || mediaId.isEmpty) {
    return Response(400,
        body: jsonEncode({'error': 'mediaId required (or valid Instagram reel URL)'}),
        headers: _json);
  }

  final uri = Uri.parse('$_igBase/$mediaId').replace(queryParameters: {
    'fields': 'id,like_count,comments_count,media_type,timestamp,permalink',
    'access_token': token,
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    return Response(res.statusCode,
        body: jsonEncode({'error': 'Instagram API error', 'detail': res.body}),
        headers: _json);
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return Response.ok(jsonEncode({
    'mediaId': mediaId,
    'likes': data['like_count'] ?? 0,
    'comments': data['comments_count'] ?? 0,
    'permalink': data['permalink'] ?? '',
  }), headers: _json);
}

/// GET `/api/instagram-handle?handle=<username>`
/// Returns follower count + recent post stats for the connected account.
/// Note: Instagram Graph API only returns stats for your own account.
Future<Response> handleInstagramHandleStats(Request request) async {
  final token = _token;
  if (token == null || token.isEmpty) {
    return Response(503,
        body: jsonEncode({'error': 'Instagram not configured'}), headers: _json);
  }

  final uri = Uri.parse('$_igBase/me').replace(queryParameters: {
    'fields': 'id,username,account_type,followers_count,follows_count,media_count',
    'access_token': token,
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    return Response(res.statusCode,
        body: jsonEncode({'error': 'Instagram API error', 'detail': res.body}),
        headers: _json);
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return Response.ok(jsonEncode({
    'handle': data['username'] ?? '',
    'followers': data['followers_count'] ?? 0,
    'following': data['follows_count'] ?? 0,
    'mediaCount': data['media_count'] ?? 0,
    'accountType': data['account_type'] ?? '',
  }), headers: _json);
}

/// Extracts the shortcode (e.g. "CxAbCdEfGhI") from an Instagram URL.
String? _extractShortcode(String url) {
  final match = RegExp(r'instagram\.com/(?:reel|p|tv)/([A-Za-z0-9_-]+)').firstMatch(url);
  return match?.group(1);
}
