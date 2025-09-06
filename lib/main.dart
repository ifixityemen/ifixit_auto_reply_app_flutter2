import 'package:flutter/material.dart';
import 'models/rule.dart';
import 'services/api_service.dart';
import 'pages/logs_page.dart'; // 👈 جديد

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IfixitAutoReplyApp());
}

class IfixitAutoReplyApp extends StatelessWidget {
  const IfixitAutoReplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IFIXIT Auto-Reply',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const RulesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  late Future<List<Rule>> _future;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchRules();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.fetchRules();
    });
    await _future.catchError((_) {}); // لتفادي كسر الـ RefreshIndicator
  }

  Future<void> _showAddRuleDialog() async {
    final keywordCtrl = TextEditingController();
    final replyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إضافة قاعدة جديدة'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الكلمة المفتاحية (keyword)',
                    hintText: 'مثال: مرحبا',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل الكلمة المفتاحية' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: replyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الرد (reply)',
                    hintText: 'مثال: أهلاً وسهلاً بك 👋',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل نص الرد' : null,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final kw = keywordCtrl.text.trim();
                  final rp = replyCtrl.text.trim();
                  await ApiService.addRule(keyword: kw, reply: rp);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('فشل إضافة القاعدة: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة القاعدة بنجاح')),
        );
        _reload();
      }
    }
  }

  /// Dialog تعديل القاعدة
  Future<void> _showEditDialog(Rule r) async {
    if (r.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن التعديل: لا يوجد معرّف (id) للقاعدة')),
      );
      return;
    }

    final kw = TextEditingController(text: r.keyword);
    final rp = TextEditingController(text: r.reply);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل القاعدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: kw,
                decoration: const InputDecoration(labelText: 'الكلمة المفتاحية (keyword)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الكلمة' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rp,
                decoration: const InputDecoration(labelText: 'الرد (reply)'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الرد' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ApiService.updateRule(
                  id: r.id!,
                  keyword: kw.text.trim(),
                  reply: rp.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('فشل التعديل: $e')));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التعديل')),
        );
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('قواعد الرد التلقائي'),
        actions: [
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogsPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Rule>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'حدث خطأ أثناء تحميل القواعد:\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
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
            final rules = snap.data ?? [];
            if (rules.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('لا توجد قواعد بعد. أضف أول قاعدة من الزر العائم (+).')),
                ],
              );
            }
            return ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = rules[i];
                return Dismissible(
                  key: ValueKey(r.id ?? '${r.keyword}-$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    if (r.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لا يمكن الحذف: لا يوجد معرّف (id)')),
                      );
                      return false;
                    }
                    return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('حذف القاعدة'),
                            content: Text('هل تريد حذف "${r.keyword}"؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    try {
                      if (r.id != null) {
                        await ApiService.deleteRule(r.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف القاعدة')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('فشل الحذف: $e')),
                        );
                      }
                    } finally {
                      _reload();
                    }
                  },
                  child: ListTile(
                    leading: const Icon(Icons.rule),
                    title: Text(r.keyword),
                    subtitle: Text(r.reply),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (r.id != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8.0),
                            child: Text('#${r.id!}'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'تعديل',
                          onPressed: () => _showEditDialog(r),
                        ),
                      ],
                    ),
                    onLongPress: () => _showEditDialog(r),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRuleDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة قاعدة'),
      ),
    );
  }
}
