class Article {
  Article({
    required this.id,
    required this.title,
    required this.topic,
    required this.summary,
    required this.content,
    required this.readMinutes,
  });

  final String id;
  final String title;
  final String topic;
  final String summary;
  final String content;
  final int readMinutes;
  bool isRead = false;
}
