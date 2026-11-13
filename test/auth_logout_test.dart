import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_app_lab_2/shared/services/auth_service.dart';

class FakeAuth extends Fake implements FirebaseAuth {
  FakeAuth(this.events);
  final List<String> events;
  @override
  Future<void> signOut() async => events.add('firebase');
}

class UnavailableGoogle extends Fake implements GoogleSignIn {
  UnavailableGoogle(this.events);
  final List<String> events;
  @override
  Future<void> signOut() async {
    events.add('google');
    throw StateError('Google plugin unavailable for this email session');
  }
}

void main() {
  test('Google cleanup failure cannot block Firebase logout', () async {
    final events = <String>[];
    await AuthService(
      auth: FakeAuth(events),
      googleSignIn: UnavailableGoogle(events),
    ).signOut();
    expect(events, ['firebase', 'google']);
  });
}
