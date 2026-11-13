import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Keeps Crashlytics behind an injectable application service.
class CrashReportingService {
  const CrashReportingService({this._crashlytics});

  static const instance = CrashReportingService();

  final FirebaseCrashlytics? _crashlytics;

  FirebaseCrashlytics get _client =>
      _crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> log(String message) => _client.log(message);

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) => _client.recordError(error, stackTrace, fatal: fatal);

  void crash() => _client.crash();
}
