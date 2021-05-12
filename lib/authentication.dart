import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitriser/storage.dart';

class AuthenticationProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //SIGN UP METHOD
  Future<String> signUp({String name, String email, String password}) async {
    try {
      User user = (await _auth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user;
      await UserStorage(uid: user.uid)
          .setUserData(myName: name, myEmail: email);
      print("USERUID: $user.uid");
      return "Signed up!";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  //SIGN IN METHOD
  Future signIn({String email, String password}) async {
    try {
      UserCredential authResult = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Signed in!");
      return authResult.user;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  //SIGN OUT METHOD
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
