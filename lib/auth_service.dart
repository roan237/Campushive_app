import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return true;

    } catch (e) {
      return false;
    }
  }

}