import 'dart:async';

import 'package:adminappweb/adminHomescreen.dart';
import 'package:adminappweb/const/themecolors.dart';
import 'package:adminappweb/controllers/firebase_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progress_dialog/progress_dialog.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: ThemeColors.primaryColor,
          textTheme: GoogleFonts.openSansTextTheme()),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  FirebaseUtils _utils = FirebaseUtils();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  checkLogin() async {
    Timer(Duration(seconds: 2), () async {
      if (await _utils.isLoggedIn()) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => AdminPanelScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.primaryColor,
      body: Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "ADMIN APP",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
            CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String email;
  String password;

  FirebaseUtils _utils = FirebaseUtils();
  ProgressDialog progressDialog;

  bool isShow = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black12,
        appBar: AppBar(title: Text("Trandport Desk Admin")),
        body: Center(
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width / 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text("Enter Login Details",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryColor)),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        fillColor: ThemeColors.primaryColor,
                        filled: true,
                        hintStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0)),
                        hintText: "Admin Email"),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    onChanged: (val) {
                      email = val;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        fillColor: ThemeColors.primaryColor,
                        filled: true,
                        hintStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0)),
                        hintText: "Admin Password"),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    onChanged: (val) {
                      password = val;
                    },
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Forgot Password",
                        style: TextStyle(color: ThemeColors.primaryColor),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  MaterialButton(
                    color: ThemeColors.primaryColor,
                    minWidth: MediaQuery.of(context).size.width / 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    onPressed: () async {
                      FirebaseUser user =
                          await _utils.signInWithUser(email, password);
                      if (user != null) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AdminHomeScreen()));
                      }
                    },
                    textColor: Colors.white,
                    child: Text("Login",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
