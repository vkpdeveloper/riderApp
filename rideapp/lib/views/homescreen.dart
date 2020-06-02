import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/apikeys.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/enums/locationview.dart';
import 'package:rideapp/model/location_details.dart';
import 'package:rideapp/model/location_result.dart';
import 'package:rideapp/providers/locationViewProvider.dart';
import 'package:rideapp/providers/orderprovider.dart';
import 'package:rideapp/providers/user_provider.dart';
import 'package:rideapp/services/firebase_auth_service.dart';
import 'package:rideapp/utils/uuid.dart';
import 'package:rideapp/views/drop_location_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController _googleMapController;
  PanelController _controller;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLocalSelected = true;
  bool isOutSideSelected = false;
  LatLng initLatLng;
  TextEditingController _pickUpController;
  TextEditingController _destinationController;
  bool isPanelOpenComplete = false;
  FocusNode _pickFocusNode = FocusNode();
  FocusNode _mainFocusNode = FocusNode();
  String mainAddress;
  Timer _debounce;
  bool hasSearchTerm = false;
  bool isSearchingCurrently = false;
  String searchVal = "";
  String googleMapsAPIKeys = APIKeys.googleMapsAPI;
  LocationResult locationResult;
  String sessionToken = Uuid().generateV4();
  List<LocationDetails> allLocations = [];
  Set<Polyline> _polyLines = {};

  getCurrentLocation() async {
    bool status = Geolocator().forceAndroidLocationManager;
    print(status);
    Geolocator()
        .checkGeolocationPermissionStatus()
        .then((GeolocationStatus status) {
      print(status);
    });
    Geolocator().getCurrentPosition().then((value) async {
      List<Address> allAddresses = await Geocoder.local
          .findAddressesFromCoordinates(
              Coordinates(value.latitude, value.longitude));
      setState(() {
        initLatLng = LatLng(value.latitude, value.longitude);
        mainAddress = allAddresses[0].addressLine;
        _pickUpController.text = mainAddress;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = PanelController();
    _pickUpController = TextEditingController();
    _destinationController = TextEditingController();
    _pickUpController.addListener(_onSearchChangedPickUp);
    _destinationController.addListener(_onSearchChangedDrop);
    getCurrentLocation();
  }

  _onSearchChangedPickUp() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_pickUpController.text);
    });
  }

  moveCamera(LatLng latLng) {
    _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(zoom: 18.0, tilt: 70.0, bearing: 180, target: latLng)));
  }

  _onSearchChangedDrop() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_destinationController.text);
    });
  }

  void searchPlace(String place) {
    if (_scaffoldKey.currentContext == null) return;

    setState(() => hasSearchTerm = place.length > 0);

    if (place.length < 1) return;

    setState(() {
      isSearchingCurrently = true;
      searchVal = "Searching locations...";
    });

    autoCompleteSearch(place);
  }

  void autoCompleteSearch(String place) {
    place = place.replaceAll(" ", "+");
    var endpoint =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "key=${googleMapsAPIKeys}&" +
            "input={$place}&sessiontoken=$sessionToken";

    if (locationResult != null) {
      endpoint += "&location=${locationResult.latLng.latitude}," +
          "${locationResult.latLng.longitude}";
    }
    http.get(endpoint).then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> predictions = data['predictions'];
        allLocations.clear();
        if (predictions.isEmpty) {
          setState(() => searchVal = "No result found");
        } else {
          for (dynamic single in predictions) {
            LocationDetails detail = LocationDetails(
                locationAddress: single['description'],
                locationID: single['place_id']);
            allLocations.add(detail);
          }
          setState(() => isSearchingCurrently = false);
        }
      }
    });
  }

  Future<LatLng> decodeAndSelectPlace(String placeId) async {
    String endpoint =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&key=$googleMapsAPIKeys";

    http.Response response = await http.get(endpoint);
    print(jsonDecode(response.body));
    Map<String, dynamic> location =
        jsonDecode(response.body)['result']['geometry']['location'];
    LatLng latLng = LatLng(location['lat'], location['lng']);
    return latLng;
  }

  @override
  Widget build(BuildContext context) {
    UserPreferences userPreferences = Provider.of<UserPreferences>(context);
    LocationViewProvider locationViewProvider =
        Provider.of<LocationViewProvider>(context);
    OrderProvider orderProvider = Provider.of<OrderProvider>(context);
    FirebaseAuthService _auth =
        Provider.of<FirebaseAuthService>(context, listen: false);
    if (userPreferences.getUserName == "") {
      userPreferences.init();
    }
    // _pickUpController.text = locationViewProvider.getPickUpPointAddress;
    // _destinationController.text =
    //     locationViewProvider.getDestinationPointAddress;
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
                onTap: () =>
                    Navigator.pushNamed(context, '/savedaddressscreen'),
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
                leading:
                    Icon(Icons.event_note, color: ThemeColors.primaryColor),
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
        body: SlidingUpPanel(
          color: Colors.white,
          controller: _controller,
          parallaxEnabled: true,
          isDraggable: true,
          collapsed: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLocalSelected = true;
                        isOutSideSelected = false;
                      });
                    },
                    child: Container(
                      height: 90,
                      padding: const EdgeInsets.all(5.0),
                      width: (MediaQuery.of(context).size.width / 2) - 20,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          border: isLocalSelected
                              ? Border.all(
                                  color: ThemeColors.primaryColor, width: 4.0)
                              : null,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100, blurRadius: 10)
                          ]),
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "asset/images/map.png",
                            height: 40,
                            width: 40,
                          ),
                          Text(
                            "Local",
                            style: TextStyle(fontSize: 15.0),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLocalSelected = false;
                        isOutSideSelected = true;
                      });
                    },
                    child: Container(
                      height: 90,
                      width: (MediaQuery.of(context).size.width / 2) - 20,
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                          border: isOutSideSelected
                              ? Border.all(
                                  color: ThemeColors.primaryColor, width: 4.0)
                              : null,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100, blurRadius: 10)
                          ]),
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "asset/images/location.png",
                            height: 40,
                            width: 40,
                          ),
                          Text(
                            "Outside Station",
                            style: TextStyle(fontSize: 14.0),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.0),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  height: 40.0,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 10.0),
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(blurRadius: 14.0, color: Colors.grey.shade100)
                    ],
                    color: ThemeColors.primaryColor,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    "Recents",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.white),
                  )),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 5,
                child: StreamBuilder(
                  stream: Firestore.instance
                      .collection('user')
                      .document(userPreferences.getUserID)
                      .collection('address')
                      .limit(2)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Center(
                          child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeColors.primaryColor),
                      ));
                    if (snapshot.data.documents.length == 0) {
                      return Center(child: Text("No recent locations"));
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ListView(
                          shrinkWrap: true,
                          children: snapshot.data.documents
                              .map((DocumentSnapshot data) {
                            return ListTile(
                              leading: Icon(Icons.watch_later),
                              title: Text(
                                data.data['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              )
            ],
          ),
          onPanelClosed: () {
            _pickFocusNode.unfocus();
            setState(() {
              isPanelOpenComplete = false;
            });
          },
          onPanelOpened: () {
            setState(() {
              isPanelOpenComplete = true;
              _pickUpController.text = mainAddress;
            });
          },
          defaultPanelState: PanelState.CLOSED,
          boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.grey.shade100)],
          maxHeight: MediaQuery.of(context).size.height,
          minHeight: (MediaQuery.of(context).size.height / 2) - 80,
          panel: !isPanelOpenComplete
              ? Container()
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      Align(
                          alignment: Alignment.topLeft,
                          child: Row(
                            children: <Widget>[
                              Icon(Octicons.primitive_dot, color: Colors.green),
                              Text(
                                  _pickFocusNode.hasFocus == true
                                      ? "Pick Up Location"
                                      : "Drop Location",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: ThemeColors.primaryColor,
                                      fontWeight: FontWeight.bold))
                            ],
                          )),
                      SizedBox(height: 20),
                      TextField(
                        onChanged: (val) {
                          locationViewProvider.setPickUpAddress(val);
                        },
                        onTap: () {
                          locationViewProvider
                              .setLocationView(LocationView.PICKUPSELECTED);
                        },
                        controller: _pickUpController,
                        focusNode: _pickFocusNode,
                        style: TextStyle(
                            color: ThemeColors.primaryColor, fontSize: 16.0),
                        autofocus: true,
                        decoration: InputDecoration(
                            prefixIcon: IconButton(
                              icon: Icon(Icons.my_location),
                              onPressed: () =>
                                  _scaffoldKey.currentState.openDrawer(),
                              color: ThemeColors.primaryColor,
                            ),
                            hintText: "Your Pickup Location",
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: ThemeColors.primaryColor),
                              borderRadius: BorderRadius.circular(10),
                            )),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                      TextField(
                        onChanged: (val) {
                          locationViewProvider.setDestinationPointAddress(val);
                        },
                        onTap: () {
                          locationViewProvider.setLocationView(
                              LocationView.DESTINATIONSELECTED);
                        },
                        controller: _destinationController,
                        style: TextStyle(
                            color: ThemeColors.primaryColor, fontSize: 16.0),
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DropLocationMap())),
                                icon: Icon(Icons.location_on)),
                            prefixIcon: IconButton(
                              icon: Icon(Icons.my_location),
                              onPressed: () =>
                                  _scaffoldKey.currentState.openDrawer(),
                              color: ThemeColors.primaryColor,
                            ),
                            hintText: "Your Drop Location",
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: ThemeColors.primaryColor),
                              borderRadius: BorderRadius.circular(10),
                            )),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: ThemeColors.primaryColor,
                        height: 8.0,
                      ),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          children: <Widget>[
                            if (isSearchingCurrently)
                              _isSearchingOrNotFound(searchVal),
                            if (!isSearchingCurrently)
                              for (LocationDetails detail in allLocations) ...[
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade100,
                                            blurRadius: 14.0)
                                      ]),
                                  child: ListTile(
                                    onTap: () async {
                                      _controller.close();
                                      LatLng getLatLng =
                                          await decodeAndSelectPlace(
                                              detail.locationID);
                                      if (getLatLng != null) {
                                        moveCamera(getLatLng);
                                        locationViewProvider
                                            .setAddress(detail.locationAddress);
                                        if (locationViewProvider
                                                .getLocationView ==
                                            LocationView.PICKUPSELECTED) {
                                          locationViewProvider
                                              .setPickUpLatLng(getLatLng);
                                        } else {
                                          locationViewProvider
                                              .setDestinationLatLng(getLatLng);
                                        }
                                      } else {
                                        print(getLatLng);
                                      }
                                    },
                                    title: Text(detail.locationAddress),
                                  ),
                                ),
                                Divider()
                              ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
          body: initLatLng == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ThemeColors.primaryColor),
                  ),
                )
              : Stack(
                  children: <Widget>[
                    GoogleMap(
                      buildingsEnabled: true,
                      polylines: _polyLines,
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        zoom: 18,
                        target: initLatLng,
                      ),
                      onMapCreated: (controller) {
                        _googleMapController = controller;
                      },
                    ),
                    _buildSearch(context),
                    _buildMyLocation(),
                    pin(),
                  ],
                ),
        ));
  }

  Widget _buildMyLocation() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height / 2 - 70),
      right: 10.0,
      child: FloatingActionButton(
        onPressed: () => _googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
                target: initLatLng, zoom: 18, bearing: 180, tilt: 60))),
        child: Icon(Icons.my_location),
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      height: 60,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 60.0,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.grey.shade100, blurRadius: 14.0)
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState.openDrawer(),
              color: ThemeColors.primaryColor,
            ),
            Expanded(
              child: TextField(
                focusNode: _mainFocusNode,
                onTap: () {
                  _mainFocusNode.unfocus();
                  _pickFocusNode.requestFocus();
                  _controller.open();
                },
                style:
                    TextStyle(color: ThemeColors.primaryColor, fontSize: 16.0),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Your Current Location",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'asset/marker.png',
              height: 45,
              width: 45,
            ),
            Container(
              decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    blurRadius: 4,
                    color: ThemeColors.primaryColor,
                  ),
                ],
                shape: CircleBorder(
                  side: BorderSide(
                    width: 4,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  Widget _isSearchingOrNotFound(String result) {
    return ListTile(
      title: Text(result),
    );
  }
}
