import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../auth.dart';
import '../store.dart';

final _json = {'content-type': 'application/json'};

Future<Response> handleLogin(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final username = (body['username'] as String?)?.trim() ?? '';
  final password = (body['password'] as String?)?.trim() ?? '';

  if (username.isEmpty || password.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'Username and password required'}), headers: _json);
  }

  final userId = await Store.instance.getUserIdByUsername(username);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Invalid username or password'}), headers: _json);
  }

  final user = (await Store.instance.getUserById(userId))!;
  if (!verifyPassword(password, user['passwordHash'] as String)) {
    return Response(401, body: jsonEncode({'error': 'Invalid username or password'}), headers: _json);
  }

  final token = generateToken(userId, username);

  return Response.ok(jsonEncode({
    'token': token,
    'user': {
      'id': userId,
      'username': user['username'],
      'displayName': user['displayName'] ?? username,
      'email': user['email'] ?? '',
      'isAdmin': user['isAdmin'] == true || username == 'zaron.films',
      'createdAt': user['createdAt'],
    },
  }), headers: _json);
}

Future<Response> handleRegister(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final username = (body['username'] as String?)?.trim() ?? '';
  final displayName = (body['displayName'] as String?)?.trim() ?? '';
  final email = (body['email'] as String?)?.trim() ?? '';
  final password = (body['password'] as String?)?.trim() ?? '';

  if (username.isEmpty || password.isEmpty || email.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'Username, email, and password required'}), headers: _json);
  }

  if (username.length < 3) {
    return Response(400, body: jsonEncode({'error': 'Username must be at least 3 characters'}), headers: _json);
  }

  if (password.length < 6) {
    return Response(400, body: jsonEncode({'error': 'Password must be at least 6 characters'}), headers: _json);
  }

  if (await Store.instance.usernameExists(username)) {
    return Response(409, body: jsonEncode({'error': 'Username already taken'}), headers: _json);
  }

  final id = Store.instance.generateId();
  final now = DateTime.now().toUtc().toIso8601String();

  await Store.instance.createUser(id, {
    'username': username,
    'displayName': displayName.isNotEmpty ? displayName : username,
    'email': email,
    'passwordHash': hashPassword(password),
    'isAdmin': false,
    'createdAt': now,
    'totalScore': 0,
    'streak': 0,
  });

  final token = generateToken(id, username);

  return Response(201, body: jsonEncode({
    'token': token,
    'user': {
      'id': id,
      'username': username,
      'displayName': displayName.isNotEmpty ? displayName : username,
      'email': email,
      'isAdmin': username == 'zaron.films',
      'createdAt': now,
    },
  }), headers: _json);
}

Future<Response> handleGetMe(Request request) async {
  final userId = getUserId(request);
  final user = await Store.instance.getUserById(userId);

  if (user == null) {
    return Response(404, body: jsonEncode({'error': 'User not found'}), headers: _json);
  }

  // Check if there's a snapshot with full session data
  final snapshot = await Store.instance.getSnapshot(userId);

  return Response.ok(jsonEncode({
    'user': {
      'id': userId,
      'username': user['username'],
      'displayName': user['displayName'] ?? user['username'],
      'email': user['email'] ?? '',
      'isAdmin': user['isAdmin'] == true || (user['username'] as String? ?? '') == 'zaron.films',
      'createdAt': user['createdAt'],
      'totalScore': user['totalScore'] ?? 0,
      'streak': user['streak'] ?? 0,
    },
    if (snapshot != null) 'snapshot': snapshot,
  }), headers: _json);
}
