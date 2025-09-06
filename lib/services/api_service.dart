import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rule.dart';
import '../models/log_entry.dart';

class ApiService {
  /// غيّر الرابط إلى رابط تطبيقك على Render
  static const String baseUrl = 'https://wa-auto-reply-starter.onrender.com';

  static Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// (اختياري) مفتاح API
  static const String? _apiKey = null; // مثلا: 'MY_SECRET';
  static Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_apiKey != null) 'x-api-key': _apiKey!,
      };

  /// إرجاع كل القواعد
  static Future<List<Rule>> fetchRules() async {
    final res = await http.get(_u('/rules'), headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .map<Rule>((e) => Rule.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Unexpected response for GET /rules: ${res.body}');
    } else {
      throw Exception('GET /rules failed: ${res.statusCode} ${res.body}');
    }
  }

  /// إضافة قاعدة جديدة
  static Future<Rule> addRule({
    required String keyword,
    required String reply,
  }) async {
    final payload = jsonEncode({'keyword': keyword, 'reply': reply});
    final res = await http.post(
      _u('/rules'),
      headers: _headers(json: true),
      body: payload,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        return Rule.fromJson(body);
      }
      // في حال رجع السيرفر {success:true} فقط
      return Rule(keyword: keyword, reply: reply);
    } else {
      throw Exception('POST /rules failed: ${res.statusCode} ${res.body}');
    }
  }

  /// حذف قاعدة
  static Future<void> deleteRule(String id) async {
    final res = await http.dele
