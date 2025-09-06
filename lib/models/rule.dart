class Rule {
  final String? id;
  final String keyword;
  final String reply;

  Rule({this.id, required this.keyword, required this.reply});

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id']?.toString(),
      keyword: json['keyword']?.toString() ?? '',
      reply: json['reply']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'reply': reply,
    };
  }
}
