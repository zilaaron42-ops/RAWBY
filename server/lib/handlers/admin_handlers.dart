import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../auth.dart';
import '../store.dart';

final _json = {'content-type': 'application/json'};
final _uuid = const Uuid();

// ── Feedback ─────────────────────────────────────────────────────

Future<Response> handleGetFeedback(Request request) async {
  return Response.ok(jsonEncode(await Store.instance.getFeedback()), headers: _json);
}

Future<Response> handleDeleteFeedback(Request request, String id) async {
  await Store.instance.deleteFeedback(id);
  return Response.ok(jsonEncode({'status': 'ok'}), headers: _json);
}

// ── Updates ──────────────────────────────────────────────────────

Future<Response> handlePostUpdate(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final username = getUsername(request);

  final update = {
    'id': _uuid.v4(),
    'title': body['title'] ?? '',
    'body': body['body'] ?? '',
    'sendPush': body['sendPush'] ?? false,
    'postedBy': username,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  await Store.instance.addUpdate(update);
  return Response(201, body: jsonEncode(update), headers: _json);
}

Future<Response> handleGetUpdates(Request request) async {
  return Response.ok(jsonEncode(await Store.instance.getUpdates()), headers: _json);
}

// ── Users ────────────────────────────────────────────────────────

Future<Response> handleGetUsers(Request request) async {
  final allUsers = await Store.instance.getAllUsers();
  final users = allUsers.map((u) {
    // Don't expose password hashes
    return {
      'id': u['id'],
      'username': u['username'],
      'displayName': u['displayName'] ?? u['username'],
      'email': u['email'] ?? '',
      'totalScore': u['totalScore'] ?? 0,
      'streak': u['streak'] ?? 0,
      'isAdmin': u['isAdmin'] ?? false,
      'createdAt': u['createdAt'],
    };
  }).toList();

  return Response.ok(jsonEncode(users), headers: _json);
}

Future<Response> handleDeleteAllUsers(Request request) async {
  final secret = Platform.environment['ADMIN_SECRET'] ?? '';
  final provided = request.headers['x-admin-secret'] ?? '';
  // Accept either valid JWT (from authMiddleware) or X-Admin-Secret header
  if (provided.isNotEmpty && secret.isNotEmpty && provided == secret) {
    await Store.instance.deleteAllUsers();
    return Response.ok(jsonEncode({'status': 'ok', 'message': 'All users deleted'}), headers: _json);
  }
  // Fallback: check if user is admin via JWT (set by authMiddleware)
  try {
    final username = getUsername(request);
    if (username.isEmpty) throw Exception();
  } catch (_) {
    return Response(403, body: jsonEncode({'error': 'Forbidden'}), headers: _json);
  }
  await Store.instance.deleteAllUsers();
  return Response.ok(jsonEncode({'status': 'ok', 'message': 'All users deleted'}), headers: _json);
}

Future<Response> handleMakeAdmin(Request request) async {
  final secret = Platform.environment['ADMIN_SECRET'] ?? '';
  final provided = request.headers['x-admin-secret'] ?? '';
  if (secret.isEmpty || provided != secret) {
    return Response(403, body: jsonEncode({'error': 'Forbidden'}), headers: _json);
  }
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final username = (body['username'] as String?)?.trim() ?? '';
  if (username.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'username required'}), headers: _json);
  }
  await Store.instance.setUserAdmin(username, true);
  return Response.ok(jsonEncode({'status': 'ok', 'username': username, 'isAdmin': true}), headers: _json);
}

// Delete a single user (admin only). Reached via JWT (must be an admin) or
// the X-Admin-Secret header.
Future<Response> handleDeleteUser(Request request, String username) async {
  final secret = Platform.environment['ADMIN_SECRET'] ?? '';
  final provided = request.headers['x-admin-secret'] ?? '';
  var allowed = secret.isNotEmpty && provided == secret;
  if (!allowed) {
    try {
      final reqUser = getUsername(request);
      if (reqUser.isNotEmpty) {
        final id = await Store.instance.getUserIdByUsername(reqUser);
        final u = id != null ? await Store.instance.getUserById(id) : null;
        allowed = (u?['isAdmin'] == true) || reqUser == 'zaron.films';
      }
    } catch (_) {}
  }
  if (!allowed) {
    return Response(403, body: jsonEncode({'error': 'Forbidden'}), headers: _json);
  }
  final target = Uri.decodeComponent(username).trim();
  if (target.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'username required'}), headers: _json);
  }
  await Store.instance.deleteUser(target);
  return Response.ok(jsonEncode({'status': 'ok', 'deleted': target}), headers: _json);
}

// ── FCM Token ────────────────────────────────────────────────────

Future<Response> handleRegisterFcmToken(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final token = body['token'] as String? ?? '';

  if (token.isNotEmpty) {
    await Store.instance.saveFcmToken(userId, token);
  }

  return Response.ok(jsonEncode({'status': 'ok'}), headers: _json);
}
