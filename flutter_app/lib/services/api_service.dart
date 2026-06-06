import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/relationship.dart';
import '../models/mood.dart';

// iOS simulator: localhost | Android emulator: 10.0.2.2 | Real device: LAN IP
const String _baseUrl = 'http://localhost:8000/api/v1';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  static Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  static Future<void> clearTokens() async => _storage.deleteAll();

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _storage.write(key: 'access_token', value: data['access']);
      return true;
    }
    return false;
  }

  // Auto-retry with token refresh on 401
  static Future<http.Response> _get(Uri uri) async {
    var headers = await _authHeaders();
    var res = await http.get(uri, headers: headers);
    if (res.statusCode == 401) {
      if (await refreshAccessToken()) {
        headers = await _authHeaders();
        res = await http.get(uri, headers: headers);
      }
    }
    return res;
  }

  static Future<http.Response> _post(Uri uri, {Map<String, dynamic>? body}) async {
    var headers = await _authHeaders();
    var res = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    if (res.statusCode == 401) {
      if (await refreshAccessToken()) {
        headers = await _authHeaders();
        res = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      }
    }
    return res;
  }

  // Auth
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    String lastName = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'first_name': firstName, 'last_name': lastName}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) await _saveTokens(data['access'], data['refresh']);
    return {'status': res.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) await _saveTokens(data['access'], data['refresh']);
    return {'status': res.statusCode, 'data': data};
  }

  // Profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final res = await _get(Uri.parse('$_baseUrl/profile/'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // Relationships
  static Future<List<Relationship>> getRelationships() async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Relationship.fromJson(j)).toList();
    }
    return [];
  }

  static Future<Relationship?> createRelationship(String type) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/'), body: {'relationship_type': type});
    if (res.statusCode == 201) return Relationship.fromJson(jsonDecode(res.body));
    return null;
  }

  static Future<HealthScore?> getHealthScore(int relId) async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/$relId/health/'));
    if (res.statusCode == 200) return HealthScore.fromJson(jsonDecode(res.body));
    return null;
  }

  static Future<bool> acceptInvite(String token) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/accept/$token/'));
    return res.statusCode == 200;
  }

  // Moods
  static Future<MoodEntry?> logMood(int relId, String mood, {String note = ''}) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/$relId/mood/'), body: {'mood': mood, 'note': note});
    if (res.statusCode == 200 || res.statusCode == 201) return MoodEntry.fromJson(jsonDecode(res.body));
    return null;
  }

  static Future<List<MoodEntry>> getMoodHistory(int relId) async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/$relId/mood/history/'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => MoodEntry.fromJson(j)).toList();
    }
    return [];
  }

  static Future<bool> logConnectionScore(int relId, int score) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/$relId/connection/'), body: {'score': score});
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Conflicts
  static Future<List<ConflictEntry>> getConflicts(int relId) async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/$relId/conflicts/'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => ConflictEntry.fromJson(j)).toList();
    }
    return [];
  }

  static Future<bool> logConflict(int relId, String category, String description, int severity) async {
    final res = await _post(
      Uri.parse('$_baseUrl/relationships/$relId/conflicts/'),
      body: {'category': category, 'description': description, 'severity': severity},
    );
    return res.statusCode == 201;
  }

  // Events
  static Future<List<dynamic>> getEvents(int relId) async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/$relId/events/'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    return [];
  }

  static Future<bool> addEvent(int relId, String type, String title, DateTime date, {bool recurring = false}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _post(
      Uri.parse('$_baseUrl/relationships/$relId/events/'),
      body: {'event_type': type, 'title': title, 'date': dateStr, 'is_recurring': recurring},
    );
    return res.statusCode == 201;
  }

  // AI Engine
  static Future<Map<String, dynamic>?> analyzeConflict(int relId, int conflictId) async {
    final res = await _post(
      Uri.parse('$_baseUrl/relationships/$relId/ai/analyze/'),
      body: {'conflict_id': conflictId},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    if (res.statusCode == 402) return {'error': 'limit_reached', ...jsonDecode(res.body)};
    return null;
  }

  static Future<Map<String, dynamic>?> detectPatterns(int relId) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/$relId/ai/patterns/'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    if (res.statusCode == 402) return {'error': 'limit_reached', ...jsonDecode(res.body)};
    return null;
  }

  static Future<Map<String, dynamic>?> generateWeeklyReport(int relId) async {
    final res = await _post(Uri.parse('$_baseUrl/relationships/$relId/ai/report/'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    if (res.statusCode == 402) return {'error': 'limit_reached', ...jsonDecode(res.body)};
    return null;
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(int relId) async {
    final res = await _get(Uri.parse('$_baseUrl/relationships/$relId/ai/coach/'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendCoachMessage(int relId, String message) async {
    final res = await _post(
      Uri.parse('$_baseUrl/relationships/$relId/ai/coach/'),
      body: {'message': message},
    );
    if (res.statusCode == 200) return {'reply': jsonDecode(res.body)['reply']};
    if (res.statusCode == 402) return {'error': 'limit_reached', ...jsonDecode(res.body)};
    return {'error': 'Failed to send message'};
  }

  // Billing
  static Future<Map<String, dynamic>?> getBillingStatus() async {
    final res = await _get(Uri.parse('$_baseUrl/billing/status/'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>?> createOrder() async {
    final res = await _post(Uri.parse('$_baseUrl/billing/create-order/'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> verifyPayment(String orderId, String paymentId, String signature) async {
    final res = await _post(Uri.parse('$_baseUrl/billing/verify/'), body: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return res.statusCode == 200;
  }

  static Future<bool> cancelSubscription() async {
    final res = await _post(Uri.parse('$_baseUrl/billing/cancel/'));
    return res.statusCode == 200;
  }

  static Future<bool> activateTestPremium() async {
    final res = await _post(Uri.parse('$_baseUrl/billing/activate-test/'));
    return res.statusCode == 200;
  }
}
