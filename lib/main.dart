import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/screens/auth_screen.dart';
import 'firebase_options.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/crash_reporting_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LongevaBootstrap());
}

class LongevaBootstrap extends StatefulWidget {
  const LongevaBootstrap({super.key});

  @override
  State<LongevaBootstrap> createState() => _LongevaBootstrapState();
}

class _LongevaBootstrapState extends State<LongevaBootstrap> {
  late Future<void> _initialization;
  late final String _initialLocation;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _initialLocation =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    _initialization = _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _authService ??= AuthService();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        FlutterError.onError = (details) {
          CrashReportingService.instance.recordError(
            details.exception,
            details.stack ?? StackTrace.current,
          );
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          CrashReportingService.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _FirebaseErrorScreen(
          onRetry: () =>
              setState(() => _initialization = _initializeFirebase()),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const _BootstrapLoadingScreen();
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final insets = mediaQuery.viewInsets;
          final sanitizedInsets = EdgeInsets.fromLTRB(
            insets.left < 0 ? 0 : insets.left,
            insets.top < 0 ? 0 : insets.top,
            insets.right < 0 ? 0 : insets.right,
            insets.bottom < 0 ? 0 : insets.bottom,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(viewInsets: sanitizedInsets),
            child: child ?? const SizedBox.shrink(),
          );
        },
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: initialRoute),
            builder: (_) => _AuthGate(
              initialLocation: _initialLocation,
              authService: _authService!,
            ),
          ),
        ],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _AuthGate(
            initialLocation: _initialLocation,
            authService: _authService!,
          ),
        ),
      );
    },
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.initialLocation, required this.authService});

  final String initialLocation;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: authService.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _BootstrapLoadingScreen();
      }
      final user = snapshot.data;
      if (user == null) return const AuthScreen();
      return LongevaApp(
        key: ValueKey(user.uid),
        initialLocation: initialLocation,
      );
    },
  );
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: CircularProgressIndicator())),
    onGenerateRoute: _loadingRoute,
  );
}

Route<void> _loadingRoute(RouteSettings settings) => MaterialPageRoute<void>(
  settings: settings,
  builder: (_) =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
);

class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Không thể khởi tạo dịch vụ Longeva.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    ),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Scaffold(
        body: Center(child: Text('Không thể khởi tạo dịch vụ Longeva.')),
      ),
    ),
  );
}
