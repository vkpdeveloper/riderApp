import 'package:adminappweb/const/themecolors.dart';
import 'package:flutter/material.dart';

class UserDetails extends StatelessWidget {
  final Map<String, dynamic> data;

  const UserDetails({Key key, this.data}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeColors.primaryColor),
        elevation: 0.0,
        backgroundColor: Colors.white,
        title: Text(
          data['name'],
          style: TextStyle(color: ThemeColors.primaryColor),
        ),
      ),
      body: SingleChildScrollView(
        
      ),
    );
  }
}