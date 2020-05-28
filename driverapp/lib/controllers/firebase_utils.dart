import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FirebaseUtils {
  FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference _firestoreUser = Firestore.instance.collection('user');

  FirebaseMessaging _messaging = FirebaseMessaging();

  Future<bool> getLoggedIn() async {
    try {
      final FirebaseUser user = await _auth.currentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<FirebaseUser> getCurrentUser() async {
    return _auth.currentUser();
  }

  Future<String> getCurrentUserToken() async {
    return _messaging.getToken();
  }

  Future<void> saveGivenData(String firstName, String lastName) async {
    FirebaseUser user = await _auth.currentUser();
    String token = await getCurrentUserToken();
    Map<String, dynamic> data = {
      "name": "${firstName} ${lastName}",
      "phone": user.phoneNumber ?? "",
      "token": token,
      "email": user.email ?? ""
    };
    await _firestoreUser.document(user.uid).setData(data, merge: true);
  }

  Future<List<String>> getAllListOfTrucks() async {
    List<String> allTrucks = [];
    QuerySnapshot snapshot =
        await Firestore.instance.collection('trucks').getDocuments();
    snapshot.documents.forEach((DocumentSnapshot truck) {
      allTrucks.add(truck.data['name']);
    });
    return allTrucks;
  }

  Future<bool> isVendorExists(String phone) async {
    DocumentSnapshot snapshot =
        await Firestore.instance.collection('vendor').document(phone).get();
    return snapshot.exists;
  }

  Future<void> signInWithPhone(AuthProvider provider) async {
    PhoneVerificationCompleted verificationComplete =
        (AuthCredential creds) async {
      AuthResult result = await _auth.signInWithCredential(creds);
      assert(result.user.uid != null);
      provider.setUser(result.user);
      print(result.user.uid);
    };
    PhoneVerificationFailed verificationFailed = (AuthException exception) {
      provider.setError(exception);
    };

    PhoneCodeSent onCodeSent = (String verificationCode, [int forceCodeSent]) {
      provider.setVerificationID(verificationCode);
      provider.setIsCodeSent(true);
    };

    PhoneCodeAutoRetrievalTimeout codeRetrievalTimeout =
        (String verificationID) {
      provider.setVerificationID(verificationID);
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: "+91${provider.phoneNumber}",
        timeout: Duration(seconds: 10),
        verificationCompleted: verificationComplete,
        verificationFailed: verificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: codeRetrievalTimeout);
  }

  Future<FirebaseUser> loginWithOTP(AuthProvider provider) async {
    try {
      AuthCredential credential = PhoneAuthProvider.getCredential(verificationId: provider.verificationID, smsCode: provider.smsCode);
    AuthResult result = await _auth.signInWithCredential(credential);
    if(result.user.uid != null) return result.user;
    } catch(e) {
      print(e.toString());
      Fluttertoast.showToast(msg: "Wrong OTP");
    }
  }
}
