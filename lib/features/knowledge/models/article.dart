class Article {
  Article({
    required this.id,
    required this.title,
    required this.topic,
    required this.summary,
    required this.content,
  });
  final String id, title, topic, summary, content;
  bool isRead = false;
}
