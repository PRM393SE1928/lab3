import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/app_state.dart';
import '../models/article.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.article});
  final Article article;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().markArticleRead(widget.article.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.article.topic)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.article.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            widget.article.content,
            style: const TextStyle(fontSize: 17, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Chip(
            avatar: Icon(Icons.check, size: 18),
            label: Text('Đã đánh dấu đã đọc'),
          ),
        ],
      ),
    );
  }
}
