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
  FirebaseUtils _utils = FirebaseUtils();

  String _username, _password;

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
                  height: _height / 5,
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
                          onPressed: () async {
                            if (_password.length == 6) {
                              authProvider.setSMSCode(_password);
                              try {
                                FirebaseUser _user =
                                    await _utils.loginWithOTP(authProvider);

                                if (_user.uid != null) {
                                  Navigator.pushNamed(context, '/homescreen');
                                } else {
                                  Fluttertoast.showToast(msg: "Login Failed");
                                }
                              } catch (e) {
                                print(e.toString());
                              }
                            } else {
                              Fluttertoast.showToast(msg: "Wrong OTP");
                            }
                          }),
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
