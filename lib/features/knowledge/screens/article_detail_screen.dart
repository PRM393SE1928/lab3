import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
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
    final article = widget.article;

    return Scaffold(
      appBar: AppBar(title: Text(article.topic)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(article.topic)),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text('${article.readMinutes} phút đọc'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Text(
              article.summary,
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.content,
            style: const TextStyle(fontSize: 17, height: 1.65),
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
