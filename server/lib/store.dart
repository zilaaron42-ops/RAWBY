import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

/// MongoDB Atlas persistent store.
/// Uses MONGO_URI environment variable for connection string.
class Store {
  Store._();
  static final Store instance = Store._();

  final _uuid = const Uuid();
  late Db _db;

  late DbCollection _users;
  late DbCollection _snapshots;
  late DbCollection _feedback;
  late DbCollection _updates;
  late DbCollection _fcmTokens;
  late DbCollection _suggestions;
  late DbCollection _communityPrompts;

  Future<void> initialize() async {
    final mongoUri = Platform.environment['MONGO_URI'] ??
        'mongodb://localhost:27017/rawby';

    _db = await Db.create(mongoUri);
    await _db.open();

    _users = _db.collection('users');
    _snapshots = _db.collection('snapshots');
    _feedback = _db.collection('feedback');
    _updates = _db.collection('updates');
    _fcmTokens = _db.collection('fcm_tokens');
    _suggestions = _db.collection('suggestions');
    _communityPrompts = _db.collection('community_prompts');

    // Ensure indexes
    await _users.createIndex(keys: {'username': 1}, unique: true);
    await _snapshots.createIndex(keys: {'userId': 1}, unique: true);
    await _fcmTokens.createIndex(keys: {'userId': 1}, unique: true);
    await _suggestions.createIndex(keys: {'userId': 1});

    print('  MongoDB connected to: ${_db.databaseName}');
  }

  // ── Users ──────────────────────────────────────────────────────

  String generateId() => _uuid.v4();

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final doc = await _users.findOne(where.eq('userId', id));
    return doc;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final doc = await _users.findOne(
      where.eq('username', username).eq('usernameLower', username.toLowerCase()),
    );
    // Fallback: search by lowercase
    if (doc != null) return doc;
    return await _users.findOne(where.eq('usernameLower', username.toLowerCase()));
  }

  Future<String?> getUserIdByUsername(String username) async {
    final doc = await _users.findOne(
      where.eq('usernameLower', username.toLowerCase()),
    );
    return doc?['userId'] as String?;
  }

  Future<bool> usernameExists(String username) async {
    final doc = await _users.findOne(
      where.eq('usernameLower', username.toLowerCase()),
    );
    return doc != null;
  }

  Future<void> createUser(String id, Map<String, dynamic> data) async {
    data['userId'] = id;
    data['usernameLower'] = (data['username'] as String).toLowerCase();
    await _users.insertOne(data);
  }

  Future<void> updateUserField(String id, String field, dynamic value) async {
    await _users.updateOne(where.eq('userId', id), modify.set(field, value));
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    data['userId'] = id;
    if (data.containsKey('username')) {
      data['usernameLower'] = (data['username'] as String).toLowerCase();
    }
    await _users.replaceOne(where.eq('userId', id), data, upsert: true);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final docs = await _users.find().toList();
    return docs.map((doc) {
      final user = Map<String, dynamic>.from(doc);
      user['id'] = user['userId'];
      user.remove('_id');
      return user;
    }).toList();
  }

  Future<void> setVerificationToken(String userId, String token) async {
    await _users.updateOne(
      where.eq('userId', userId),
      modify.set('verificationToken', token).set('emailVerified', false),
    );
  }

  Future<Map<String, dynamic>?> getUserByVerificationToken(String token) async {
    final doc = await _users.findOne(where.eq('verificationToken', token));
    return doc;
  }

  Future<void> deleteAllUsers() async {
    await _users.deleteMany({});
    await _snapshots.deleteMany({});
    await _fcmTokens.deleteMany({});
  }

  Future<void> setUserAdmin(String username, bool isAdmin) async {
    await _users.updateOne(
      where.eq('usernameLower', username.toLowerCase()),
      modify.set('isAdmin', isAdmin),
    );
  }

  Future<void> markUserVerified(String userId) async {
    await _users.updateOne(
      where.eq('userId', userId),
      modify.set('emailVerified', true).unset('verificationToken'),
    );
  }

  Future<String?> getUserEmailById(String userId) async {
    final doc = await _users.findOne(where.eq('userId', userId));
    return doc?['email'] as String?;
  }

  // ── Snapshots (sync) ───────────────────────────────────────────

  Future<void> saveSnapshot(String userId, Map<String, dynamic> snapshot) async {
    snapshot['userId'] = userId;
    await _snapshots.replaceOne(
      where.eq('userId', userId),
      snapshot,
      upsert: true,
    );
  }

  Future<Map<String, dynamic>?> getSnapshot(String userId) async {
    final doc = await _snapshots.findOne(where.eq('userId', userId));
    if (doc != null) {
      doc.remove('_id');
      doc.remove('userId');
    }
    return doc;
  }

  // ── Feedback ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFeedback() async {
    final docs = await _feedback.find().toList();
    return docs.map((d) {
      d.remove('_id');
      return Map<String, dynamic>.from(d);
    }).toList();
  }

  Future<void> addFeedback(Map<String, dynamic> item) async {
    await _feedback.insertOne(item);
  }

  Future<void> deleteFeedback(String id) async {
    await _feedback.deleteOne(where.eq('id', id));
  }

  // ── Updates ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUpdates() async {
    final docs = await _updates.find(where.sortBy('createdAt', descending: true)).toList();
    return docs.map((d) {
      d.remove('_id');
      return Map<String, dynamic>.from(d);
    }).toList();
  }

  Future<void> addUpdate(Map<String, dynamic> update) async {
    await _updates.insertOne(update);
  }

  // ── FCM Tokens ─────────────────────────────────────────────────

  Future<void> saveFcmToken(String userId, String token) async {
    await _fcmTokens.replaceOne(
      where.eq('userId', userId),
      {'userId': userId, 'token': token},
      upsert: true,
    );
  }

  Future<Map<String, String>> getAllFcmTokens() async {
    final docs = await _fcmTokens.find().toList();
    return {for (final d in docs) d['userId'] as String: d['token'] as String};
  }

  // ── Suggestions ────────────────────────────────────────────────

  Future<String> addSuggestion(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    data['id'] = id;
    data['createdAt'] = DateTime.now().toIso8601String();
    await _suggestions.insertOne(data);
    return id;
  }

  Future<List<Map<String, dynamic>>> getSuggestionsForUser(String userId) async {
    final docs = await _suggestions
        .find(where.eq('userId', userId).sortBy('createdAt', descending: true))
        .toList();
    return docs.map((d) { d.remove('_id'); return Map<String, dynamic>.from(d); }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllSuggestions() async {
    final docs = await _suggestions
        .find(where.sortBy('createdAt', descending: true))
        .toList();
    return docs.map((d) { d.remove('_id'); return Map<String, dynamic>.from(d); }).toList();
  }

  Future<void> replySuggestion(String id, String reply) async {
    await _suggestions.updateOne(
      where.eq('id', id),
      modify.set('adminReply', reply).set('repliedAt', DateTime.now().toIso8601String()),
    );
  }

  // ── Community Prompts ──────────────────────────────────────────

  Future<void> saveCommunityPrompt(Map<String, dynamic> data) async {
    data['id'] = _uuid.v4();
    data['createdAt'] = DateTime.now().toIso8601String();
    await _communityPrompts.insertOne(data);
  }

  Future<List<Map<String, dynamic>>> getRecentCommunityPrompts({int limit = 6}) async {
    final docs = await _communityPrompts
        .find(where.sortBy('createdAt', descending: true).limit(limit))
        .toList();
    return docs.map((d) { d.remove('_id'); return Map<String, dynamic>.from(d); }).toList();
  }
}
