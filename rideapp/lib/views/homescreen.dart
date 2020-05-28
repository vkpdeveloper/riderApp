import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/static_utils.dart';
import 'package:rideapp/enums/locationview.dart';
import 'package:rideapp/providers/locationViewProvider.dart';
import 'package:rideapp/providers/orderprovider.dart';
import 'package:rideapp/providers/user_provider.dart';
import 'package:rideapp/services/firebase_auth_service.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GoogleMapController _mapsController;
  LatLng initLatLng;
  bool isBottomSheetEnabled = false;
  StaticUtils _utils = StaticUtils();
  Set<Marker> _markers = {};
  BitmapDescriptor pinLocationIcon;
  bool isPanelOpenComplete = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _utils.getBytesFromAsset('asset/images/marker.png', 64).then((value) {
      pinLocationIcon = BitmapDescriptor.fromBytes(value);
    });
  }

  showCurrentLocationOnSheet(LocationViewProvider provider) async {
    final Coordinates coordinates =
        Coordinates(initLatLng.latitude, initLatLng.longitude);
    String address = await _utils.getAddressOnCords(coordinates);
    provider.setAddress(address);
  }

  getCurrentLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
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
    OrderProvider orderProvider = Provider.of<OrderProvider>(context);
    UserPreferences userPreferences = Provider.of<UserPreferences>(context);
    LocationViewProvider locationViewProvider =
        Provider.of<LocationViewProvider>(context);
    return Scaffold(
      drawer: Drawer(
        elevation: 8.0,
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userPreferences.getUserName),
              accountEmail: Text(userPreferences.getUserPhone != ""
                  ? userPreferences.getUserPhone
                  : userPreferences.getUserEmail),
            ),
            ListTile(
              onTap: () => Navigator.pushNamed(context, '/savedaddressscreen'),
              leading:
                  Icon(Icons.location_city, color: ThemeColors.primaryColor),
              title: Text(
                "Saved Address",
                style: TextStyle(color: ThemeColors.primaryColor),
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
              leading:
                  Icon(Icons.person_outline, color: ThemeColors.primaryColor),
              title: Text(
                "Update Profile",
                style: TextStyle(color: ThemeColors.primaryColor),
              ),
            ),
            ListTile(
              onTap: () => Navigator.pushNamed(context, '/allordersscreen'),
              leading: Icon(Icons.event_note, color: ThemeColors.primaryColor),
              title: Text(
                "All Bookings",
                style: TextStyle(color: ThemeColors.primaryColor),
              ),
            ),
            ListTile(
              leading: Icon(Feather.info, color: ThemeColors.primaryColor),
              title: GestureDetector(
                onTap: () {
                  _auth.signOut();
                  Navigator.pushReplacementNamed(context, '/loginscreen');
                },
                child: Text(
                  "About",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
              ),
            ),
            ListTile(
              leading: Icon(AntDesign.customerservice,
                  color: ThemeColors.primaryColor),
              title: GestureDetector(
                onTap: () {
                  _auth.signOut();
                  Navigator.pushReplacementNamed(context, '/loginscreen');
                },
                child: Text(
                  "Support",
                  style: TextStyle(color: ThemeColors.primaryColor),
                ),
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
      body: SlidingUpPanel(
        backdropEnabled: false,
        defaultPanelState: PanelState.CLOSED,
        isDraggable: true,
        header: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text("HELLO, ${userPreferences.getUserName}",
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                    color: Theme.of(context).primaryColor)),
          ),
        ),
        onPanelClosed: () {
          setState(() => isPanelOpenComplete = false);
        },
        onPanelOpened: () {
          setState(() => isPanelOpenComplete = true);
        },
        collapsed: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 45.0),
          child: InkWell(
            onTap: () {
              locationViewProvider.setLocationView(LocationView.PICKUPSELECTED);
            },
            child: Ink(
              width: MediaQuery.of(context).size.width,
              height: 50.0,
              child: Column(
                children: <Widget>[
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Pickup Point",
                          style: TextStyle(
                              fontSize: 14.0, color: Colors.black45))),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.location_on,
                            color: locationViewProvider.getLocationView ==
                                    LocationView.PICKUPSELECTED
                                ? Colors.blue
                                : ThemeColors.primaryColor),
                        SizedBox(width: 10.0),
                        Flexible(
                          child: Text(
                            locationViewProvider.getPickUpPointAddress == ""
                                ? "Fetching..."
                                : locationViewProvider.getPickUpPointAddress,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: ThemeColors.primaryColor,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        minHeight: (MediaQuery.of(context).size.height / 6),
        maxHeight: (MediaQuery.of(context).size.height / 3 - 20),
        panel: isPanelOpenComplete
            ? Padding(
                padding: const EdgeInsets.only(
                    right: 15.0, left: 15.0, top: 30.0, bottom: 15),
                child: Stack(
                  children: [
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        InkWell(
                          onTap: () {
                            locationViewProvider
                                .setLocationView(LocationView.PICKUPSELECTED);
                          },
                          child: Ink(
                            width: MediaQuery.of(context).size.width,
                            height: 50.0,
                            child: Column(
                              children: <Widget>[
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Pickup Point",
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black45))),
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.location_on,
                                          color: locationViewProvider
                                                      .getLocationView ==
                                                  LocationView.PICKUPSELECTED
                                              ? Colors.blue
                                              : ThemeColors.primaryColor),
                                      SizedBox(width: 10.0),
                                      Flexible(
                                        child: Text(
                                          locationViewProvider
                                                      .getPickUpPointAddress ==
                                                  ""
                                              ? "Fetching..."
                                              : locationViewProvider
                                                  .getPickUpPointAddress,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: ThemeColors.primaryColor,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        InkWell(
                          onTap: () {
                            locationViewProvider.setLocationView(
                                LocationView.DESTINATIONSELECTED);
                          },
                          child: Ink(
                            width: MediaQuery.of(context).size.width,
                            height: 50.0,
                            child: Column(
                              children: <Widget>[
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Destination Point",
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black45))),
                                Stack(
                                  overflow: Overflow.visible,
                                  children: <Widget>[
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.location_on,
                                              color: locationViewProvider
                                                          .getLocationView ==
                                                      LocationView
                                                          .DESTINATIONSELECTED
                                                  ? Colors.blue
                                                  : ThemeColors.primaryColor),
                                          SizedBox(width: 10.0),
                                          Flexible(
                                            child: Text(
                                              locationViewProvider
                                                          .getDestinationPointAddress ==
                                                      ""
                                                  ? "Not yet selected"
                                                  : locationViewProvider
                                                      .getDestinationPointAddress,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color:
                                                      ThemeColors.primaryColor,
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                        bottom: -10.0,
                                        right: 0.0,
                                        child: IconButton(
                                          iconSize: 25.0,
                                          onPressed: () {},
                                          icon: Icon(Icons.more_vert),
                                          color: ThemeColors.primaryColor,
                                        ))
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: FloatingActionButton(
                            onPressed: () {
                              if (true) {
                                orderProvider
                                    .setOrderPrice(locationViewProvider);
                                Navigator.pushNamed(
                                    context, '/orderdetailsscreen');
                              }
                            },
                            backgroundColor: ThemeColors.primaryColor,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.arrow_forward_ios)))
                  ],
                ),
              )
            : Container(),
        body: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            initLatLng != null
                ? Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: GoogleMap(
                      markers: _markers,
                      onTap: (LatLng newPosition) async {
                        if (_markers.isNotEmpty) {
                          _markers.clear();
                        }
                        _markers.add(Marker(
                            markerId: MarkerId("1"),
                            position: newPosition,
                            icon: pinLocationIcon));
                        setState(() {
                          initLatLng = newPosition;
                        });
                        final Coordinates coordinates = Coordinates(
                            newPosition.latitude, newPosition.longitude);
                        locationViewProvider.setAddress("Fetching...");
                        String myAddress =
                            await _utils.getAddressOnCords(coordinates);
                        locationViewProvider.setAddress(myAddress);
                        if (locationViewProvider.getLocationView ==
                            LocationView.PICKUPSELECTED)
                          locationViewProvider.setPickUpLatLng(newPosition);
                        else
                          locationViewProvider
                              .setDestinationLatLng(newPosition);
                      },
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      buildingsEnabled: true,
                      scrollGesturesEnabled: true,
                      mapType: MapType.terrain,
                      initialCameraPosition:
                          CameraPosition(target: initLatLng, zoom: 14.0),
                      onMapCreated: (GoogleMapController controller) {
                        showCurrentLocationOnSheet(locationViewProvider);
                        locationViewProvider.setPickUpLatLng(initLatLng);
                        _mapsController = controller;
                      },
                    ))
                : Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.primaryColor),
                    ),
                  ),
            Positioned(
              top: 30.0,
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
      ),
    );
  }
}
