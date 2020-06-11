import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/firebase_utils.dart';
import 'package:rideapp/views/emailandPassword_login.dart';
import 'package:rideapp/widgets/otp_input.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _user;
  FirebaseUtils _utils = FirebaseUtils();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  TextEditingController _pinEditingController = TextEditingController();

  Future<FirebaseUser> signIn(AuthCredential authCreds) async {
    try {
      AuthResult result = await _firebaseAuth.signInWithCredential(authCreds);
      return result.user;
    } catch (e) {
      Fluttertoast.showToast(msg: "Invalid OTP Code");
      return null;
    }
  }

  signInWithOTP(smsCode, verId) async {
    AuthCredential authCreds = PhoneAuthProvider.getCredential(
        verificationId: verId, smsCode: smsCode);
    FirebaseUser _user = await signIn(authCreds);
    assert(_user.uid != null);
    if (_user != null) {
      print(_user.uid);
      Navigator.pushReplacementNamed(context, '/customerscreen');
    }
  }

  Future<void> verifyPhone(phoneNo) async {
    final PhoneVerificationCompleted verified =
        (AuthCredential authResult) async {
      FirebaseUser _user = await signIn(authResult);
      if (_user != null) {
        print(_user.uid);
        Navigator.pushReplacementNamed(context, '/customerscreen');
      }
    };

    final PhoneVerificationFailed verificationfailed =
        (AuthException authException) {
      print('${authException.message}');
    };

    final PhoneCodeSent smsSent = (String verId, [int forceResend]) {
      this.verificationId = verId;
      setState(() {
        this.codeSent = true;
      });
    };

    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        timeout: const Duration(seconds: 60),
        verificationCompleted: verified,
        verificationFailed: verificationfailed,
        codeSent: smsSent,
        codeAutoRetrievalTimeout: autoTimeout);
  }

  Future<void> googleSignIn() async {
    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    AuthResult result = (await _auth.signInWithCredential(credential));
    assert(result.user.uid != null);
    _user = result.user;
    print(_user.uid);
    _utils.saveGoogleLoginData();
    Navigator.pushReplacementNamed(context, '/homescreen');
  }

  GoogleSignIn _googleSignIn = GoogleSignIn();

  String phoneNo, verificationId, smsCode;

  bool codeSent = false;

  PinDecoration _pinDecoration = UnderlineDecoration(
      textStyle: TextStyle(color: Colors.white),
      color: Colors.white,
      enteredColor: Colors.white,
      hintText: '666666',
      obscureStyle: ObscureStyle(isTextObscure: true));

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    final double _height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          height: _height,
          width: _width,
          child: ListView(
            children: <Widget>[
              Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  Container(
                    width: _width,
                    height: _height / 1.8,
                    decoration: BoxDecoration(color: ThemeColors.primaryColor),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 30,
                    child: Center(
                      child: Text(
                        "Login Using Phone Number",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0),
                      ),
                    ),
                  ),
                  codeSent
                      ? Container()
                      : Positioned(
                          child: Container(
                              width: (_width / 2) + 100,
                              child: Material(
                                elevation: 15.0,
                                color: Colors.white10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                                shadowColor: ThemeColors.primaryColor,
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                      prefix: Text(
                                        "+91  ",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      fillColor: ThemeColors.primaryColor,
                                      filled: true,
                                      focusedBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(20.0)),
                                      hintStyle: TextStyle(color: Colors.white),
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      labelText: "Enter Phone Number",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.0))),
                                  onChanged: (val) {
                                    setState(() {
                                      this.phoneNo = "+91$val";
                                      print(phoneNo);
                                    });
                                  },
                                ),
                              )),
                          bottom: -23,
                          left: 50,
                          right: 50,
                        ),
                  codeSent
                      ? Positioned(
                          child: Container(
                              width: (_width / 2) + 100,
                              child: Material(
                                elevation: 15.0,
                                color: ThemeColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                                shadowColor: ThemeColors.primaryColor,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(14, 0, 14, 5),
                                  child: PinInputTextField(
                                    pinLength: 6,
                                    decoration: _pinDecoration,
                                    controller: _pinEditingController,
                                    autoFocus: true,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (pin) {
                                      if (pin.length == 6) {
                                        setState(() {
                                          this.smsCode = pin;
                                          print(smsCode);
                                        });
                                      } else {}
                                    },
                                  ),
                                ),
                              )),
                          bottom: -23,
                          left: 50,
                          right: 50,
                        )
                      : Container(),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    child: MaterialButton(
                        color: Colors.blue,
                        child: Center(
                            child: codeSent
                                ? Text(
                                    'Login',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  )
                                : Text(
                                    'Get Otp',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  )),
                        onPressed: () {
                          codeSent
                              ? signInWithOTP(smsCode, verificationId)
                              : verifyPhone(phoneNo);
                        }),
                  ),
                ),
              ),
              Center(
                child: RichText(
                  text: TextSpan(
                      text: "Or",
                      style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryColor)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 10.0),
                child: Column(
                  children: <Widget>[
                    MaterialButton(
                      color: Colors.red,
                      onPressed: () {
                        googleSignIn();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            AntDesign.google,
                            color: Colors.white,
                            size: 25.0,
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Text(
                            "Google",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    MaterialButton(
                      color: Colors.blue,
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            FontAwesome.facebook,
                            color: Colors.white,
                            size: 25.0,
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Text(
                            "Facebook",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_icons/flutter_icons.dart';
// import 'package:rideapp/constants/themecolors.dart';
// import 'package:rideapp/views/otpscreen.dart';

// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Container(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           child: ListView(
//             children: <Widget>[
//               Stack(
//                 overflow: Overflow.visible,
//                 children: <Widget>[
//                   Container(
//                     width: MediaQuery.of(context).size.width,
//                     height: MediaQuery.of(context).size.height / 3,
//                     decoration: BoxDecoration(color: ThemeColors.primaryColor),
//                   ),
//                   Positioned(
//                     bottom: 60,
//                     left: 30,
//                     child: Center(
//                       child: Text(
//                         "Login Using Phone Number",
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18.0),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     child: Container(
//                         width: (MediaQuery.of(context).size.width / 2) + 100,
//                         child: Material(
//                           elevation: 15.0,
//                           color: Colors.white10,
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20.0)),
//                           shadowColor: ThemeColors.primaryColor,
//                           child: TextField(
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                                 prefix: Text(
//                                   "+91  ",
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 fillColor: ThemeColors.primaryColor,
//                                 filled: true,
//                                 focusedBorder: OutlineInputBorder(
//                                     borderSide: BorderSide(color: Colors.white),
//                                     borderRadius: BorderRadius.circular(20.0)),
//                                 hintText: "Enter Mobile Number",
//                                 hintStyle: TextStyle(color: Colors.white),
//                                 labelStyle: TextStyle(color: Colors.white),
//                                 labelText: "Mobile Number",
//                                 border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(20.0))),
//                           ),
//                         )),
//                     bottom: -23,
//                     left: 50,
//                     right: 50,
//                   )
//                 ],
//               ),
//               SizedBox(
//                 height: 50,
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 50.0),
//                 child: Align(
//                   alignment: Alignment.topRight,
//                   child: Container(
//                     child: FloatingActionButton(
//                       onPressed: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => OTPScreen(
//                                     mobileNumber: "9984150296",
//                                   ))),
//                       mini: false,
//                       tooltip: "Click to Login",
//                       foregroundColor: Colors.white,
//                       child: Icon(Icons.arrow_forward_ios),
//                       backgroundColor: ThemeColors.primaryColor,
//                     ),
//                   ),
//                 ),
//               ),
//               Center(
//                 child: RichText(
//                   text: TextSpan(
//                       text: "Social Account Login",
//                       style: TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                           color: ThemeColors.primaryColor)),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 30.0, vertical: 30.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: <Widget>[
//                     GestureDetector(
//                       onTap: () => print("Hello World"),
//                       child: Container(
//                           height: 50.0,
//                           width: (MediaQuery.of(context).size.width / 2) - 50,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                               boxShadow: [
//                                 BoxShadow(
//                                     blurRadius: 20.0,
//                                     spreadRadius: 2.0,
//                                     color: Colors.deepOrange.shade200)
//                               ],
//                               borderRadius: BorderRadius.circular(25.0),
//                               gradient: LinearGradient(
//                                   begin: Alignment.centerLeft,
//                                   end: Alignment.centerRight,
//                                   colors: [
//                                     Colors.redAccent,
//                                     Colors.deepOrange
//                                   ])),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: <Widget>[
//                               Icon(
//                                 AntDesign.google,
//                                 color: Colors.white,
//                                 size: 25.0,
//                               ),
//                               SizedBox(
//                                 width: 10.0,
//                               ),
//                               Text(
//                                 "Google",
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 18.0,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           )),
//                     ),
//                     SizedBox(
//                       width: 15.0,
//                     ),
//                     GestureDetector(
//                       onTap: () => print("Hello World"),
//                       child: Container(
//                           height: 50.0,
//                           width: (MediaQuery.of(context).size.width / 2) - 50,
//                           alignment: Alignment.center,
//                           decoration: BoxDecoration(
//                               boxShadow: [
//                                 BoxShadow(
//                                     blurRadius: 20.0,
//                                     spreadRadius: 2.0,
//                                     color: Colors.lightBlue.shade200)
//                               ],
//                               borderRadius: BorderRadius.circular(25.0),
//                               gradient: LinearGradient(
//                                   begin: Alignment.centerLeft,
//                                   end: Alignment.centerRight,
//                                   colors: [Colors.lightBlue, Colors.blue])),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: <Widget>[
//                               Icon(
//                                 FontAwesome.facebook,
//                                 color: Colors.white,
//                                 size: 25.0,
//                               ),
//                               SizedBox(
//                                 width: 10.0,
//                               ),
//                               Text(
//                                 "Facebook",
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 18.0,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           )),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
