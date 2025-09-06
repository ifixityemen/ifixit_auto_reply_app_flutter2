import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../services/api_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late Future<List<LogEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchLogs();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.fetchLogs();
    });
    await _future.catchError((_) {});
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    // 2025-09-06 14:35:12
    return local.toString().split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل التنفيذ')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<LogEntry>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'تعذر تحميل السجل:\n${snap.error}\n\n'
                      'لو ما فعّلت /logs في السيرفر، هذا متوقع. سنفعّلها لاحقًا.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ),
                ],
              );
            }
            final logs = snap.data ?? [];
            if (logs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('لا توجد سجلات بعد.')),
                ],
              );
            }
            return ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = logs[i];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(e.message),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.matchedKeyword != null && e.matchedKeyword!.isNotEmpty)
                        Text('Keyword: ${e.matchedKeyword}'),
                      Text('Reply: ${e.reply}'),
                      if (e.from.isNotEmpty) Text('From: ${e.from}'),
                      if (e.timestamp != null) Text(_fmtTime(e.timestamp)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
