import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/app_state.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});
  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final articles = context
        .watch<AppState>()
        .articles
        .where(
          (a) => '${a.title} ${a.topic}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kiến thức',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm bài viết',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 20),
          ...articles.map(
            (article) => Card(
              child: ListTile(
                onTap: () => context.push('/article', extra: article),
                title: Text(
                  article.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${article.topic}\n${article.summary}'),
                isThreeLine: true,
                trailing: article.isRead
                    ? const Icon(Icons.check_circle_outline)
                    : const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
