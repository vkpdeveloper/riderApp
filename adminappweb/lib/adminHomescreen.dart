import 'package:flutter/material.dart';


class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome Admin")),
      body: Center(
        child: Container(
         child:  Text("HomeScreen")
        ),
      )
    );
  }
}