class LogEntry {
  final String? id;
  final String from;
  final String message;
  final String? matchedKeyword;
  final String reply;
  final DateTime? timestamp;

  LogEntry({
    this.id,
    required this.from,
    required this.message,
    this.matchedKeyword,
    required this.reply,
    this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    final t = json['timestamp'];
    if (t != null) {
      try {
        ts = DateTime.tryParse(t.toString());
      } catch (_) {}
    }
    return LogEntry(
      id: json['id']?.toString(),
      from: json['from']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      matchedKeyword: json['matchedKeyword']?.toString(),
      reply: json['reply']?.toString() ?? '',
      timestamp: ts,
    );
  }
}
