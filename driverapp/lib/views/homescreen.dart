import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/controllers/firebase_utils.dart';
import 'package:driverapp/providers/user_sharedpref_provider.dart';
import 'package:driverapp/views/signup/Verification.dart';
import 'package:driverapp/views/trackorder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:driverapp/constants/themecolors.dart';
import 'package:driverapp/services/firebase_auth_service.dart';

// to check if user exists in vendor list

class VerificationCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _fireutils = FirebaseUtils();
    Future vendorexists = _fireutils.isVendorExists();
    return FutureBuilder(
      future: vendorexists,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final _exists = snapshot.data;
          if (_exists) {
            return HomeScreen();
          }
          return Verification();
        } else {
          return Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GoogleMapController _mapsController;
  LatLng initLatLng;
  bool isBottomSheetEnabled = false;
  FirebaseUtils _firebaseUtils = FirebaseUtils();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  getCurrentLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        initLatLng = LatLng(position.latitude, position.longitude);
      });
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _auth = Provider.of<FirebaseAuthService>(context, listen: false);
    UserPreferences userPreferences = Provider.of<UserPreferences>(context);
    final double _width = MediaQuery.of(context).size.width;
    final double _height = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: AppBar(
          title: Text("Home"),
        ),
        drawer: Drawer(
          elevation: 20.0,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profilescreen');
                },
                child: UserAccountsDrawerHeader(
                  accountName: Text("Vaibhav pathak"),
                  accountEmail: Text("Phone No or Email or other info"),
                  currentAccountPicture: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                        "https://vaibhavpathakofficial.tk/img/vaibhav.png"),
                    backgroundColor: ThemeColors.primaryColor,
                  ),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/walletscreen'),
                leading: Icon(Icons.account_balance_wallet,
                    color: ThemeColors.primaryColor),
                title: Text(
                  "Wallet",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/bookings'),
                leading: Icon(Icons.history, color: ThemeColors.primaryColor),
                title: Text(
                  "History",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/notification'),
                leading:
                    Icon(Icons.notifications, color: ThemeColors.primaryColor),
                title: Text(
                  "Notifications",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/referral'),
                leading:
                    Icon(Icons.card_giftcard, color: ThemeColors.primaryColor),
                title: Text(
                  "Invite Friends",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/MAKESUPPORT'),
                leading: Icon(Icons.phone, color: ThemeColors.primaryColor),
                title: Text(
                  "Support",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                leading: Icon(Icons.settings, color: ThemeColors.primaryColor),
                title: Text(
                  "Settings",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.exit_to_app, color: ThemeColors.primaryColor),
                title: GestureDetector(
                  onTap: () {
                    _auth.signOut();
                    Navigator.pushReplacementNamed(context, '/loginscreen');
                  },
                  child: Text(
                    "Logout",
                    style: TextStyle(color: ThemeColors.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        key: _scaffoldKey,
        body: StreamBuilder(
          stream: Firestore.instance
              .collection('allOrders')
              .where("riderPhone", isEqualTo: userPreferences.getUserPhone)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.primaryColor)));
            } else {
              if (snapshot.data.documents.length == 0)
                return Center(child: Text("NO ORDERS !"));
              else {
                return ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot order) {
                    double distance = order.data['distance'];
                    String newDistance =
                        double.parse(distance.toString()).toStringAsFixed(2);
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 20.0, left: 20.0, top: 15.0, bottom: 10.0),
                      child: Container(
                        width: _width - 30,
                        height: _height / 4,
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade100,
                                  blurRadius: 10.0,
                                  spreadRadius: 10.0)
                            ],
                            borderRadius: BorderRadius.circular(15.0)),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: [
                                Icon(
                                  Octicons.primitive_dot,
                                  color: Colors.green,
                                  size: 25.0,
                                ),
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "ORDER ID : ${order.documentID}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0),
                                    )),
                              ],
                            ),
                            SizedBox(height: 5),
                            Align(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${order.data['receiverName']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0),
                                    ),
                                    Text(
                                      "$newDistance KM",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0),
                                    ),
                                    Text(
                                      "Price : ${order.data['price']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.0),
                                    ),
                                  ],
                                )),
                            SizedBox(height: 5),
                            Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Pickup address = ${order.data['addresses'][0]}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.0),
                                )),
                            SizedBox(height: 5),
                            Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Drop address = ${order.data['addresses'][1]}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.0),
                                )),
                            SizedBox(height: 7.0),
                            Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TrackOrder(
                                                orderID: order.documentID,
                                              ))),
                                  icon: Icon(Icons.arrow_forward_ios),
                                  color: ThemeColors.primaryColor,
                                ))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
            }
          },
        ));
  }
}
