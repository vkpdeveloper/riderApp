import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUtils {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<FirebaseUser> signInWithUser(String email, String password) async {
    AuthResult result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  Future<bool> isLoggedIn() async {
    FirebaseUser _user = await _auth.currentUser();
    return _user.uid != null;
  }
}
