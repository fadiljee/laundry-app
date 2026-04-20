import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('Email tidak terdaftar.');
      } else if (e.code == 'wrong-password') {
        print('Password salah.');
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}