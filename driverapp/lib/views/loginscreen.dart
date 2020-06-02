// import 'dart:async';

// import 'package:driverapp/controllers/firebase_utils.dart';
// import 'package:driverapp/providers/auth_provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:driverapp/constants/themecolors.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';

// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final formKey = GlobalKey<FormState>();
//   FirebaseAuth _auth = FirebaseAuth.instance;
//   FirebaseUtils _utils = FirebaseUtils();

//   String _username, _password;
//   bool _isTenSecondDone = false;

//   int counter = 10;

//   makeItZero() {
//     Timer.periodic(Duration(seconds: 1), (timer) {
//       print(counter);
//       if (counter == 0) {
//         setState(() {
//           timer.cancel();
//           _isTenSecondDone = true;
//         });
//       }
//       setState(() {
//         counter--;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double _width = MediaQuery.of(context).size.width;
//     final double _height = MediaQuery.of(context).size.height;
//     AuthProvider authProvider = Provider.of<AuthProvider>(context);

//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: ThemeColors.primaryColor,
//         body: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.only(right: 20, left: 20.0, top: 100),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisSize: MainAxisSize.max,
//               children: <Widget>[
//                 Container(
//                     height: 150,
//                     width: 150,
//                     child: Image.asset("assets/images/logonew.png")),
//                 SizedBox(
//                   height: _height / 4,
//                 ),
//                 Material(
//                   elevation: 15.0,
//                   color: Colors.white10,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20.0)),
//                   shadowColor: ThemeColors.primaryColor,
//                   child: TextFormField(
//                     keyboardType: TextInputType.text,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                         prefix: Text("+91"),
//                         fillColor: Colors.black12,
//                         filled: true,
//                         focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.white),
//                             borderRadius: BorderRadius.circular(20.0),
//                             gapPadding: 0),
//                         hintStyle: TextStyle(color: Colors.white),
//                         labelStyle: TextStyle(color: Colors.white),
//                         labelText: "Phone Number",
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.0))),
//                     onChanged: (val) {
//                       setState(() {
//                         _username = "+91 + $val";
//                       });
//                     },
//                   ),
//                 ),
//                 SizedBox(
//                   height: 10,
//                 ),
//                 if (authProvider.getIsCodeSent && _isTenSecondDone)
//                   Material(
//                     elevation: 15.0,
//                     color: Colors.white10,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20.0)),
//                     shadowColor: ThemeColors.primaryColor,
//                     child: TextFormField(
//                       keyboardType: TextInputType.text,
//                       style: TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                           fillColor: Colors.black12,
//                           filled: true,
//                           focusedBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Colors.white),
//                               borderRadius: BorderRadius.circular(20.0),
//                               gapPadding: 0),
//                           hintStyle: TextStyle(color: Colors.white),
//                           labelStyle: TextStyle(color: Colors.white),
//                           labelText: "OTP Code",
//                           border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(20.0))),
//                       onChanged: (val) {
//                         setState(() {
//                           _password = val;
//                         });
//                       },
//                     ),
//                   ),
//                 if (authProvider.getIsCodeSent && !_isTenSecondDone) ...[
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: <Widget>[
//                       Text(
//                         "Trying to detect OTP : ",
//                         style: TextStyle(color: Colors.white, fontSize: 16.0),
//                       ),
//                       Text(counter.toString(),
//                           style: TextStyle(color: Colors.white, fontSize: 16.0))
//                     ],
//                   )
//                 ],
//                 SizedBox(
//                   height: 20,
//                 ),
//                 if (authProvider.getIsCodeSent)
//                   Align(
//                     alignment: Alignment.topRight,
//                     child: Container(
//                       child: MaterialButton(
//                           color: Colors.blue,
//                           child: Center(
//                               child: Text(
//                             'Verify',
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18.0,
//                                 fontWeight: FontWeight.bold),
//                           )),
//                           onPressed: _isTenSecondDone
//                               ? () async {
//                                   if (_password.length == 6) {
//                                     authProvider.setSMSCode(_password);
//                                     try {
//                                       FirebaseUser _user = await _utils
//                                           .loginWithOTP(authProvider);
//                                       if (_user.uid != null) {
//                                         Navigator.pushNamed(
//                                             context, '/homescreen');
//                                       } else {
//                                         Fluttertoast.showToast(
//                                             msg: "Login Failed");
//                                       }
//                                     } catch (e) {
//                                       print(e.toString());
//                                     }
//                                   } else {
//                                     Fluttertoast.showToast(msg: "Wrong OTP");
//                                   }
//                                 }
//                               : null),
//                     ),
//                   ),
//                 if (!authProvider.getIsCodeSent)
//                   Align(
//                     alignment: Alignment.topRight,
//                     child: Container(
//                       child: MaterialButton(
//                           color: Colors.blue,
//                           child: Center(
//                               child: Text(
//                             'Login',
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18.0,
//                                 fontWeight: FontWeight.bold),
//                           )),
//                           onPressed: () async {
//                             // bool isValid =
//                             //     await _utils.isVendorExists(_username);
//                             // if (isValid) {
//                             //   authProvider.setPhoneNumber(_username);
//                             //   try {
//                             //     _utils.signInWithPhone(authProvider);
//                             //     makeItZero();
//                             //   } catch (e) {
//                             //     print(e.toString());
//                             //   }
//                             // } else {
//                             //   Fluttertoast.showToast(
//                             //       msg: "You are not know a vendor");
//                             // }

//                             // Navigator.pushNamed(context, '/homescreen');

//                             authProvider.setPhoneNumber(_username);
//                             _utils.signInWithPhone(authProvider);
//                             makeItZero();
//                           }),
//                     ),
//                   ),
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: MaterialButton(
//                       minWidth: _width / 2,
//                       color: Colors.blue,
//                       child: Center(
//                           child: Text(
//                         'Login debug',
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18.0,
//                             fontWeight: FontWeight.bold),
//                       )),
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/homescreen');
//                       }),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:driverapp/controllers/firebase_utils.dart';
import 'package:driverapp/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/constants/themecolors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUtils _utils = FirebaseUtils();

  String _username, _password;
  bool _isTenSecondDone = false;

  int counter = 10;

  makeItZero() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      print(counter);
      if (counter == 0) {
        setState(() {
          timer.cancel();
          _isTenSecondDone = true;
        });
      }
      setState(() {
        counter--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    final double _height = MediaQuery.of(context).size.height;
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: ThemeColors.primaryColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, left: 20.0, top: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    height: 200,
                    width: 200,
                    child: Image.asset("assets/images/logonew.png")),
                SizedBox(
                  height: _height / 4,
                ),
                Material(
                  elevation: 15.0,
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  shadowColor: ThemeColors.primaryColor,
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        prefix: Text("+91"),
                        fillColor: Colors.black12,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(20.0),
                            gapPadding: 0),
                        hintStyle: TextStyle(color: Colors.white),
                        labelStyle: TextStyle(color: Colors.white),
                        labelText: "Phone Number",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0))),
                    onChanged: (val) {
                      setState(() {
                        _username = val;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                if (authProvider.getIsCodeSent && _isTenSecondDone)
                  Material(
                    elevation: 15.0,
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    shadowColor: ThemeColors.primaryColor,
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          fillColor: Colors.black12,
                          filled: true,
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(20.0),
                              gapPadding: 0),
                          hintStyle: TextStyle(color: Colors.white),
                          labelStyle: TextStyle(color: Colors.white),
                          labelText: "OTP Code",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0))),
                      onChanged: (val) {
                        setState(() {
                          _password = val;
                        });
                      },
                    ),
                  ),
                if (authProvider.getIsCodeSent && !_isTenSecondDone) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Trying to detect OTP : ",
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      Text(counter.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 16.0))
                    ],
                  )
                ],
                SizedBox(
                  height: 20,
                ),
                if (authProvider.getIsCodeSent)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      child: MaterialButton(
                          color: Colors.blue,
                          child: Center(
                              child: Text(
                            'Verify',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          )),
                          onPressed: _isTenSecondDone
                              ? () async {
                                  if (_password.length == 6) {
                                    authProvider.setSMSCode(_password);
                                    try {
                                      FirebaseUser _user = await _utils
                                          .loginWithOTP(authProvider);

                                      if (_user.uid != null) {
                                        Navigator.pushNamed(
                                            context, '/homescreen');
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Login Failed");
                                      }
                                    } catch (e) {
                                      print(e.toString());
                                    }
                                  } else {
                                    Fluttertoast.showToast(msg: "Wrong OTP");
                                  }
                                }
                              : null),
                    ),
                  ),
                if (!authProvider.getIsCodeSent)
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      child: MaterialButton(
                          color: Colors.blue,
                          child: Center(
                              child: Text(
                            'Login',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          )),
                          onPressed: () async {
                            authProvider.setPhoneNumber(_username);
                            try {
                              _utils.signInWithPhone(authProvider);
                              makeItZero();
                            } catch (e) {
                              print(e.toString());
                            }
                          }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
