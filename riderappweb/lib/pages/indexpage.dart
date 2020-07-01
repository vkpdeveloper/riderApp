import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riderappweb/Components/app_bar.dart';
import 'package:riderappweb/Components/features.dart';
import 'dart:js' as js;

import 'package:riderappweb/controllers/js_intercop.dart';

class IndexPage extends StatefulWidget {
  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _singleChildScrollController = ScrollController();

  Animation _animation;
  AnimationController _animationController;
  Animation _animationString;

  bool isCodeSent = false;

  TextEditingController _phoneController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _animation = Tween(begin: -1.0, end: 0.0).animate(
        CurvedAnimation(curve: Curves.linear, parent: _animationController));
    _animationString = Tween<String>(begin: "", end: "TRANSPORT DESK").animate(
        CurvedAnimation(curve: Curves.linear, parent: _animationController));
    _singleChildScrollController.addListener(() {
      print("Hello World");
      if (_singleChildScrollController.position.pixels < size.height) {
        _singleChildScrollController.animateTo(size.height + 50,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        _animationController.forward();
      }
    });
  }

  showLoginDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Login"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                      hintText: "Enter Phone",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25)),
                      prefix: Text("+91 ")),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
                SizedBox(height: 20),
                MaterialButton(
                    minWidth: 250,
                    onPressed: () {},
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    textColor: Colors.white,
                    color: Theme.of(context).primaryColor,
                    child: Text("LOGIN"))
              ],
            ),
          );
        });
  }

  showRegisterDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Register"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                      hintText: "Enter Name",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25))),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                      hintText: "Enter Phone",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25)),
                      prefix: Text("+91 ")),
                ),
                if (isCodeSent) ...[
                  SizedBox(height: 15),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Enter OTP",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                MaterialButton(
                    minWidth: 250,
                    onPressed: () async {
                      if (isCodeSent) {
                        var user = await js.context
                            .callMethod('verifyOTP', [_otpController.text]);
                        if (user != null) {
                          print(user);
                        } else {
                          print("Somethign went wrong !");
                        }
                      } else {
                        
                        var p1 = new js.JsObject(
                            js.context['FirbasePhoneAuth'], ['+918318045008']);
                        print(p1['recaptchaVerifier']);
                        print(p1['phoneNumber']);
                        print(p1.callMethod('generateCaptcha'));
                        print(p1['recaptchaVerifier']);
                        Timer(Duration(seconds: 2),
                            () async {var data = await p1.callMethod('sendOTP'); print(data)});
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    textColor: Colors.white,
                    color: Theme.of(context).primaryColor,
                    child: Text(isCodeSent ? "REGISTER" : "VERIFY"))
              ],
            ),
          );
        });
  }

  Size size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    print(size.width);
    return Scaffold(
      body: SingleChildScrollView(
        controller: _singleChildScrollController,
        child: Column(
          children: [
            Container(
              height: size.height,
              width: size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomAppBar(
                      animationController: _animationController,
                      scrollController: _singleChildScrollController,
                      width: size.width,
                      showLoginDialog: showLoginDialog,
                      showRegisterDialog: showRegisterDialog,
                      height: size.height),
                ],
              ),
            ),
            SizedBox(height: 20),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, widget) {
                return Transform(
                  transform: Matrix4.translationValues(
                      _animation.value * size.width, 0, 0),
                  child: Container(
                    width: size.width,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 20,
                        spacing: 40,
                        runAlignment: WrapAlignment.spaceAround,
                        children: [
                          Feature(
                            feature: "Fast Delivery".toUpperCase(),
                          ),
                          Feature(
                            feature: "Experinced Drivers".toUpperCase(),
                          ),
                          Feature(
                            feature:
                                "Reasonable Pricing for All ".toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Container(
              width: size.width,
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  direction: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TRANSPORT DESK",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25.0,
                                color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "A TRUCK FOR EVERYONE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                                color: Colors.white),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            children: [
                              Icon(
                                Icons.call,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "+919999999999",
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            children: [
                              Icon(
                                Icons.mail,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "maaro@gmail.com",
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            children: [
                              Icon(
                                Icons.business,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Haamare Ghar ke pass aur sharma ke ghar ke bagal",
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
