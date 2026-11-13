import 'package:firebase_core/firebase_core.dart';

import 'app_repository.dart';
import 'firestore_repository.dart';
import 'mock_repository.dart';

/// Chooses the cloud repository outside the widget layer.
class RepositoryFactory {
  const RepositoryFactory._();

  static AppRepository create() =>
      Firebase.apps.isEmpty ? MockRepository() : FirestoreAppRepository();
}
