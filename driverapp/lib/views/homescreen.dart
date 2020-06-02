import 'dart:async';

import 'package:driverapp/controllers/firebase_utils.dart';
import 'package:driverapp/views/signup/Verification.dart';
import 'package:driverapp/views/splashscreen.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      drawer: Drawer(
        elevation: 8.0,
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
              onTap: () => Navigator.pushNamed(context, '/updateprofile'),
              leading:
                  Icon(Icons.person_outline, color: ThemeColors.primaryColor),
              title: Text(
                "Update Profile",
                style: TextStyle(color: ThemeColors.primaryColor),
              ),
            ),
            ListTile(
              onTap: () => Navigator.pushNamed(context, '/allordersscreen'),
              leading: Icon(Icons.phone, color: ThemeColors.primaryColor),
              title: Text(
                "Support",
                style: TextStyle(color: ThemeColors.primaryColor),
              ),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: ThemeColors.primaryColor),
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
      body: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          initLatLng != null
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: GoogleMap(
                    onTap: (LatLng newPosition) {
                      setState(() {
                        initLatLng = newPosition;
                      });
                    },
                    myLocationButtonEnabled: false,
                    myLocationEnabled: true,
                    buildingsEnabled: true,
                    scrollGesturesEnabled: true,
                    mapType: MapType.terrain,
                    initialCameraPosition:
                        CameraPosition(target: initLatLng, zoom: 14.0),
                    onMapCreated: (GoogleMapController controller) {
                      _mapsController = controller;
                    },
                  ))
              : Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ThemeColors.primaryColor),
                  ),
                ),
          Positioned(
            top: 50.0,
            left: 20.0,
            child: FloatingActionButton(
              heroTag: 'menu',
              onPressed: () => _scaffoldKey.currentState.openDrawer(),
              backgroundColor: ThemeColors.primaryColor,
              foregroundColor: Colors.white,
              child: Icon(Icons.menu),
            ),
          ),
        ],
      ),
    );
  }
}
