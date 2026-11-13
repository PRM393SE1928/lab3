import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<void> _syncProfile(User? user) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[Firestore] profile sync failed project=${FirebaseFirestore.instance.app.options.projectId} '
        'path=users/{uid} code=${error.code} message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[Firestore] profile sync failed path=users/{uid} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncProfile(result.user);
    return result;
  }

  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    await _syncProfile(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final result = await _auth.signInWithPopup(GoogleAuthProvider());
      await _syncProfile(result.user);
      return result;
    }
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final tokens = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: tokens.idToken);
    final result = await _auth.signInWithCredential(credential);
    await _syncProfile(result.user);
    return result;
  }

  Future<void> signOut() async {
    // Firebase owns the app session. Google cleanup must never block logout
    // for email accounts or platforms where GoogleSignIn is unavailable.
    await NotificationService.instance.removeCurrentToken();
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } on Object catch (error) {
      debugPrint('Google session cleanup after logout: $error');
    }
  }

  String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Email chưa đúng định dạng.',
        'user-not-found' ||
        'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
        'wrong-password' => 'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
        'network-request-failed' => 'Không có kết nối mạng. Hãy thử lại.',
        'too-many-requests' => 'Có quá nhiều yêu cầu. Hãy thử lại sau.',
        _ => 'Không thể hoàn tất yêu cầu tài khoản. Hãy thử lại.',
      };
    }
    return 'Đã có lỗi xảy ra. Hãy thử lại.';
  }
}
