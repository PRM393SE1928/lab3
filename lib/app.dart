import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/app_state.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/repository_factory.dart';

class LongevaApp extends StatefulWidget {
  const LongevaApp({super.key, this.initialLocation = '/'});

  final String initialLocation;

  @override
  State<LongevaApp> createState() => _LongevaAppState();
}

class _LongevaAppState extends State<LongevaApp> {
  late final _router = AppRouter.create(
    initialLocation: widget.initialLocation,
  );

  @override
  void initState() {
    super.initState();
    AppRouter.router = _router;
    NotificationService.instance.start();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) {
      final repository = RepositoryFactory.create();
      return AppState(repository)..hydrate();
    },
    child: MaterialApp.router(
      scaffoldMessengerKey: NotificationService.instance.messengerKey,
      title: 'Longeva',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          _SanitizeMediaQuery(child: _RepositoryGate(child: child)),
      routerConfig: _router,
    ),
  );
}

class _SanitizeMediaQuery extends StatelessWidget {
  const _SanitizeMediaQuery({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final insets = mediaQuery.viewInsets;
    final padding = mediaQuery.padding;
    final viewPadding = mediaQuery.viewPadding;

    final sanitizedInsets = EdgeInsets.fromLTRB(
      insets.left < 0 ? 0 : insets.left,
      insets.top < 0 ? 0 : insets.top,
      insets.right < 0 ? 0 : insets.right,
      insets.bottom < 0 ? 0 : insets.bottom,
    );
    final sanitizedPadding = EdgeInsets.fromLTRB(
      padding.left < 0 ? 0 : padding.left,
      padding.top < 0 ? 0 : padding.top,
      padding.right < 0 ? 0 : padding.right,
      padding.bottom < 0 ? 0 : padding.bottom,
    );
    final sanitizedViewPadding = EdgeInsets.fromLTRB(
      viewPadding.left < 0 ? 0 : viewPadding.left,
      viewPadding.top < 0 ? 0 : viewPadding.top,
      viewPadding.right < 0 ? 0 : viewPadding.right,
      viewPadding.bottom < 0 ? 0 : viewPadding.bottom,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(
        viewInsets: sanitizedInsets,
        padding: sanitizedPadding,
        viewPadding: sanitizedViewPadding,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _RepositoryGate extends StatelessWidget {
  const _RepositoryGate({this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isHydrating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.hydrateError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không thể tải dữ liệu của bạn.'),
              FilledButton(
                onPressed: state.hydrate,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final content = child ?? const SizedBox.shrink();
    if (state.lastPersistenceError == null) return content;
    return Stack(
      children: [
        content,
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.cloud_off_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  'Không thể đồng bộ dữ liệu',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Kiểm tra mạng rồi thử lại thao tác.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Đóng thông báo',
                  onPressed: state.clearPersistenceError,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
