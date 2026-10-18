import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/app_state.dart';
import 'shared/services/mock_repository.dart';

class LongevaApp extends StatelessWidget {
  const LongevaApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AppState(MockRepository()),
    child: MaterialApp.router(
      title: 'Longeva',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    ),
  );
}
