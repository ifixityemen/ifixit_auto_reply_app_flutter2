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
        sp.getString('baseUrl') ?? 'https://wa-auto-reply-starter.onrender.com';
  }

  Future<void> _saveBaseUrl() async {
    final url = _normalizedBaseUrl();
    if (url == null) {
      setState(() => _status = 'الرجاء إدخال رابط صحيح يبدأ بـ http/https');
      return;
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString('baseUrl', url);
    setState(() => _status = 'تم حفظ الرابط.');
  }

  String? _normalizedBaseUrl() {
    var url = _baseUrlCtrl.text.trim();
    if (!url.startsWith('http')) return null;
    url = url.replaceAll(RegExp(r'/+$'), '');
    return url;
  }

  Future<void> _fetchRules() async {
    final base = _normalizedBaseUrl();
    if (base == null) {
      setState(() => _status = 'أدخل رابطًا صحيحًا أولاً');
      return;
    }
    setState(() => _status = 'جلب القواعد...');
    try {
      final res = await http
          .get(Uri.parse('$base/rules'))
          .timeout(const Duration(seconds: 30));
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

  Future<void> _openAddRuleDialog() async {
    final keywordCtrl = TextEditingController();
    final replyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة قاعدة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keywordCtrl,
              decoration: const InputDecoration(labelText: 'الكلمة المفتاحية'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: replyCtrl,
              decoration: const InputDecoration(labelText: 'نص الرد'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (ok == true) {
      await _addRule(keywordCtrl.text.trim(), replyCtrl.text.trim());
    }
  }

  Future<void> _addRule(String keyword, String reply) async {
    if (keyword.isEmpty || reply.isEmpty) {
      setState(() => _status = 'الحقول مطلوبة');
      return;
    }
    final base = _normalizedBaseUrl();
    if (base == null) {
      setState(() => _status = 'أدخل رابطًا صحيحًا أولاً');
      return;
    }

    setState(() => _status = 'جارٍ الإضافة...');
    try {
      final res = await http
          .post(
            Uri.parse('$base/rules'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'keyword': keyword, 'reply': reply}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _status = 'تمت الإضافة بنجاح ✅');
        await _fetchRules(); // حدّث القائمة
      } else {
        setState(() => _status = 'فشل الإضافة: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      setState(() => _status = 'خطأ في الاتصال أثناء الإضافة: $e');
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
                title: Text('${r['keyword'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('${r['reply'] ?? ''}', style: const TextStyle(fontSize: 16)),
              )),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRuleDialog,
        label: const Text('إضافة قاعدة'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
