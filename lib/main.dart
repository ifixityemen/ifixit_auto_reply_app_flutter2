import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iFixit Auto Reply',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _baseUrlCtrl = TextEditingController();
  String _status = 'جاهز';
  List<dynamic> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    _baseUrlCtrl.text =
        sp.getString('baseUrl') ?? 'https://auto-reply-server.onrender.com';
  }

  Future<void> _saveBaseUrl() async {
    final url = _baseUrlCtrl.text.trim();
    if (!url.startsWith('http')) {
      setState(() => _status = 'الرجاء إدخال رابط صحيح يبدأ بـ http/https');
      return;
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString('baseUrl', url);
    setState(() => _status = 'تم حفظ الرابط.');
  }

  Future<void> _fetchRules() async {
    setState(() => _status = 'جلب القواعد...');
    try {
      final base = _baseUrlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
      final res = await http.get(Uri.parse('$base/rules'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _rules = (data is List) ? data : [];
          _status = 'تم الجلب (${_rules.length}) قاعدة';
        });
      } else {
        setState(() => _status = 'فشل الجلب: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'خطأ في الاتصال: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة iFixit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Base URL (رابط الخادم):'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _baseUrlCtrl,
                  decoration: const InputDecoration(
                    hintText: 'https://your-app.onrender.com',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saveBaseUrl, child: const Text('حفظ')),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _fetchRules,
            child: const Text('جلب القواعد من الخادم'),
          ),
          const SizedBox(height: 8),
          Text(_status),
          const Divider(height: 32),
          const Text('القواعد:'),
          ..._rules.map((r) => ListTile(
                title: Text('${r['keyword'] ?? ''}'),
                subtitle: Text('${r['reply'] ?? ''}'),
              )),
        ],
      ),
    );
  }
}
