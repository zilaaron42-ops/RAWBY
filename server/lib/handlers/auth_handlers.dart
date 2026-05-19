import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../auth.dart';
import '../store.dart';

final _uuid = const Uuid();

Future<void> _sendVerificationEmail(String toEmail, String token) async {
  final key = Platform.environment['RESEND_API_KEY'] ?? '';
  if (key.isEmpty) {
    print('[email] RESEND_API_KEY not set — skipping email');
    return;
  }
  final verifyUrl = 'https://rawby-1.onrender.com/api/verify-email?token=$token';
  final res = await http.post(
    Uri.parse('https://api.resend.com/emails'),
    headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'from': 'RAWBY <onboarding@resend.dev>',
      'reply_to': ['zaron.films@gmail.com'],
      'to': [toEmail],
      'subject': 'Verify your RAWBY account',
      'html': '''
<div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px;background:#0f1923;color:#fff;border-radius:12px">
  <h2 style="color:#fff;margin-bottom:4px">Welcome to RAWBY</h2>
  <p style="color:#aaa;margin-top:0">Verify your email to start your weekly filmmaking challenge.</p>
  <a href="$verifyUrl"
     style="display:inline-block;margin-top:24px;padding:14px 28px;background:#7c3aed;color:#fff;text-decoration:none;border-radius:8px;font-weight:700;font-size:16px">
    Verify Email
  </a>
  <p style="color:#666;font-size:12px;margin-top:32px">If you didn't create a RAWBY account, ignore this email.</p>
</div>
''',
    }),
  );
  if (res.statusCode >= 400) {
    print('[email] Resend error ${res.statusCode}: ${res.body}');
  }
}

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

  final isAdmin = user['isAdmin'] == true || username == 'zaron.films';
  if (!isAdmin && user['emailVerified'] == false) {
    return Response(403, body: jsonEncode({
      'error': 'email_not_verified',
      'message': 'Please verify your email before logging in. Check your inbox.',
    }), headers: _json);
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
    'emailVerified': false,
    'createdAt': now,
    'totalScore': 0,
    'streak': 0,
  });

  final verifyToken = _uuid.v4();
  await Store.instance.setVerificationToken(id, verifyToken);
  await _sendVerificationEmail(email, verifyToken);

  return Response(201, body: jsonEncode({
    'pending': true,
    'message': 'Account created. Check your email to verify your account.',
  }), headers: _json);
}

Future<Response> handleVerifyEmail(Request request) async {
  final token = request.url.queryParameters['token'] ?? '';
  if (token.isEmpty) {
    return Response(400,
        body: _verifyPage(success: false, message: 'Missing verification token.'),
        headers: {'content-type': 'text/html'});
  }

  final user = await Store.instance.getUserByVerificationToken(token);
  if (user == null) {
    return Response(400,
        body: _verifyPage(success: false, message: 'Invalid or expired link. Please register again.'),
        headers: {'content-type': 'text/html'});
  }

  await Store.instance.markUserVerified(user['userId'] as String);

  return Response(200,
      body: _verifyPage(success: true, message: 'Email verified! You can now log in to RAWBY.'),
      headers: {'content-type': 'text/html'});
}

String _verifyPage({required bool success, required String message}) => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RAWBY — Email Verification</title>
  <style>
    body { font-family: sans-serif; background: #0f1923; color: #fff; display: flex;
           align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .card { background: #1a2535; border-radius: 16px; padding: 40px 32px; max-width: 400px;
            text-align: center; border: 1px solid #2a3545; }
    h2 { margin-bottom: 12px; color: ${success ? '#4ade80' : '#f87171'}; }
    p  { color: #aaa; line-height: 1.6; }
    a  { display: inline-block; margin-top: 24px; padding: 12px 28px;
         background: #7c3aed; color: #fff; border-radius: 8px; text-decoration: none;
         font-weight: 700; }
  </style>
</head>
<body>
  <div class="card">
    <h2>${success ? '✓ Verified' : '✗ Error'}</h2>
    <p>$message</p>
    ${success ? '<a href="https://rawby-1.onrender.com">Open RAWBY</a>' : ''}
  </div>
</body>
</html>
''';

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
