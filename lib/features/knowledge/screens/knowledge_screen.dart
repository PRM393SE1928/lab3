import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_view.dart';
import '../../../shared/services/app_state.dart';
import '../models/article.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  String query = '';
  String selectedTopic = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final topics = [
      'Tất cả',
      ...{for (final article in state.articles) article.topic},
    ];
    final articles = state.articles.where(_matchesFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kiến thức',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiến thức về ăn uống trường thọ',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final topic = topics[index];
                return ChoiceChip(
                  label: Text(topic),
                  selected: selectedTopic == topic,
                  onSelected: (_) => setState(() => selectedTopic = topic),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${state.readArticleCount}/${state.articles.length} bài đã đọc',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: state.articleCompletionRatio),
          const SizedBox(height: 18),
          if (articles.isEmpty)
            const AppEmptyView(message: 'Không tìm thấy bài viết phù hợp.')
          else
            ...articles.map((article) => _ArticleCard(article: article)),
        ],
      ),
    );
  }

  bool _matchesFilter(Article article) {
    final normalizedQuery = query.trim().toLowerCase();
    final matchesTopic =
        selectedTopic == 'Tất cả' || article.topic == selectedTopic;
    final searchText = '${article.title} ${article.topic} ${article.summary}'
        .toLowerCase();
    return matchesTopic &&
        (normalizedQuery.isEmpty || searchText.contains(normalizedQuery));
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.push('/article', extra: article),
      leading: CircleAvatar(
        child: Icon(article.isRead ? Icons.check : Icons.auto_stories_outlined),
      ),
      title: Text(
        article.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${article.topic} • ${article.readMinutes} phút đọc\n'
          '${article.summary}',
        ),
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
