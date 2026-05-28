import 'dart:convert';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

// ── Config ───────────────────────────────────────────────────────
String get _jwtSecret {
  final secret = Platform.environment['JWT_SECRET'];
  if (secret == null || secret.isEmpty) {
    throw StateError('JWT_SECRET env var not set');
  }
  return secret;
}
const _tokenExpiry = Duration(days: 30);

// ── Password Hashing ─────────────────────────────────────────────

String hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

bool _isBcryptHash(String hash) => hash.startsWith(r'$2');

String _sha256Hash(String password) =>
    sha256.convert(utf8.encode(password)).toString();

/// Handles both bcrypt and legacy SHA-256 hashes. Never throws.
bool verifyPassword(String password, String hash) {
  if (_isBcryptHash(hash)) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (_) {
      return false;
    }
  }
  return _sha256Hash(password) == hash;
}

/// If hash is legacy SHA-256 and password matches, returns new bcrypt hash to store.
String? upgradeLegacyHash(String password, String currentHash) {
  if (_isBcryptHash(currentHash)) return null;
  if (_sha256Hash(password) != currentHash) return null;
  return hashPassword(password);
}

// ── JWT ──────────────────────────────────────────────────────────

String generateToken(String userId, String username) {
  final jwt = JWT({
    'sub': userId,
    'username': username,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });
  return jwt.sign(
    SecretKey(_jwtSecret),
    expiresIn: _tokenExpiry,
  );
}

Map<String, dynamic>? verifyToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

// ── Middleware ────────────────────────────────────────────────────

/// Extracts userId from the Authorization header and adds it to request context.
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
      }

      final token = authHeader.substring(7);
      final payload = verifyToken(token);
      if (payload == null) {
        return Response(401, body: jsonEncode({'error': 'Invalid or expired token'}));
      }

      final updatedRequest = request.change(context: {
        'userId': payload['sub'] as String,
        'username': payload['username'] as String,
      });
      return innerHandler(updatedRequest);
    };
  };
}

/// Helper to get userId from request context
String getUserId(Request request) => request.context['userId'] as String;
String getUsername(Request request) => request.context['username'] as String;
