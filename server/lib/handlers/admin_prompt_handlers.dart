import 'dart:convert';
import 'package:shelf/shelf.dart';

final _json = {'content-type': 'application/json'};

// In-memory store — replace with DB persistence as needed
final List<Map<String, dynamic>> _draftPrompts = [];

Future<Response> handleSaveAdminPrompt(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final text = (data['text'] as String? ?? '').trim();
    if (text.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Prompt text required'}), headers: _json);
    }

    final prompt = {
      'id': 'admin_${DateTime.now().millisecondsSinceEpoch}',
      'text': text,
      'level': data['level'] as String? ?? 'Sequence',
      'difficulty': data['difficulty'] as String? ?? 'medium',
      'points': (data['points'] as num?)?.toInt() ?? 50,
      'inspiration': data['inspiration'] as String? ?? '',
      'source': 'admin',
      'status': 'draft',
      'createdAt': DateTime.now().toIso8601String(),
    };

    _draftPrompts.add(prompt);

    return Response.ok(jsonEncode({'success': true, 'prompt': prompt}), headers: _json);
  } catch (e) {
    return Response(500, body: jsonEncode({'error': e.toString()}), headers: _json);
  }
}

Future<Response> handleGetAdminPrompts(Request request) async {
  return Response.ok(
    jsonEncode({'prompts': _draftPrompts}),
    headers: _json,
  );
}
