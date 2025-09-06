class Rule {
  final String? id;
  final String keyword;
  final String reply;

  Rule({this.id, required this.keyword, required this.reply});

  factory Rule.fromJson(Map<String, dynamic> json) {
    final anyId = (json['id'] ?? json['_id'] ?? json['ruleId'] ?? json['uuid']);
    return Rule(
      id: anyId?.toString(),
      // لو السيرفر يستخدم أسماء مختلفة غيّرها هنا:
      keyword: (json['keyword'] ?? json['key'] ?? json['phrase'] ?? '').toString(),
      reply: (json['reply'] ?? json['response'] ?? json['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'reply': reply,
    };
  }
}
