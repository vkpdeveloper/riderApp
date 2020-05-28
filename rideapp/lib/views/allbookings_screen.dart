import 'package:flutter/material.dart';
import 'package:rideapp/constants/themecolors.dart';

class AllBookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add),
            color: Colors.white
          )
        ],
        backgroundColor: ThemeColors.primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text("Booking History"),
      ),
    );
  }
}