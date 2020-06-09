import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/apikeys.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/enums/locationview.dart';
import 'package:rideapp/enums/station_view.dart';
import 'package:rideapp/enums/view_state.dart';
import 'package:rideapp/model/location_details.dart';
import 'package:rideapp/model/location_result.dart';
import 'package:rideapp/providers/locationViewProvider.dart';
import 'package:rideapp/providers/orderprovider.dart';
import 'package:rideapp/providers/user_provider.dart';
import 'package:rideapp/services/firebase_auth_service.dart';
import 'package:rideapp/utils/uuid.dart';
import 'package:rideapp/views/drop_location_screen.dart';
import 'package:rideapp/widgets/truck_cat_widget.dart';
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
  double zoomView = 18;
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
  ViewState _viewState = ViewState.DEFAULT;
  FocusNode _dropFocusNode = FocusNode();

  getCurrentLocation() async {
    _pickUpController.text = "Fetching...";
    bool status = Geolocator().forceAndroidLocationManager;
    print(status);
    Geolocator()
        .checkGeolocationPermissionStatus()
        .then((GeolocationStatus status) {
      print(status);
    });
    try {
      Position pos = await Geolocator().getCurrentPosition();

      // List<Address> allAddresses = await Geocoder.local
      //     .findAddressesFromCoordinates(
      //         Coordinates(pos.latitude, pos.longitude));
      http.Response res = await http.get(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&key=${APIKeys.googleMapsAPI}');
      var data = jsonDecode(res.body);
      var addressGet = data['results'][0]['formatted_address'];
      setState(() {
        initLatLng = LatLng(pos.latitude, pos.longitude);
        mainAddress = addressGet;
        _pickUpController.text = mainAddress;
      });
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: "Error in getting address");
    }
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
    return WillPopScope(
      onWillPop: () async {
        if (isPanelOpenComplete) {
          _controller.close();
        } else {
          return true;
        }
      },
      child: Scaffold(
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
                  leading: Icon(Icons.location_city,
                      color: ThemeColors.primaryColor),
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
                  onTap: () =>
                      Navigator.pushNamed(context, '/profile', arguments: {
                    "pref": userPreferences,
                  }),
                  leading: Icon(Icons.person_outline,
                      color: ThemeColors.primaryColor),
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
                    onTap: () {},
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
                    onTap: () {},
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
            collapsed: _renderCollapsed(orderProvider, locationViewProvider),
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
              if (locationViewProvider.getLocationView ==
                  LocationView.PICKUPSELECTED) {
                _pickFocusNode.requestFocus();
              } else {
                _dropFocusNode.requestFocus();
              }
            },
            defaultPanelState: PanelState.CLOSED,
            boxShadow: [
              BoxShadow(blurRadius: 10.0, color: Colors.grey.shade100)
            ],
            maxHeight: MediaQuery.of(context).size.height,
            minHeight: (MediaQuery.of(context).size.height / 2) - 80,
            panel: !isPanelOpenComplete
                ? Container()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 50, horizontal: 20),
                    child: Column(
                      children: <Widget>[
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: <Widget>[
                                Icon(Octicons.primitive_dot,
                                    color: ThemeColors.primaryColor),
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TextField(
                                    onChanged: (val) {
                                      locationViewProvider
                                          .setPickUpAddress(val);
                                    },
                                    onTap: () {
                                      locationViewProvider.setLocationView(
                                          LocationView.PICKUPSELECTED);
                                    },
                                    controller: _pickUpController,
                                    focusNode: _pickFocusNode,
                                    style: TextStyle(
                                        color: ThemeColors.primaryColor,
                                        fontSize: 16.0),
                                    autofocus: true,
                                    decoration: InputDecoration(
                                        icon: Icon(Octicons.primitive_dot,
                                            color: Colors.black38),
                                        hintText: "Your Pickup Location",
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: ThemeColors.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        )),
                                  ),
                                  SizedBox(height: 10.0),
                                  TextField(
                                    focusNode: _dropFocusNode,
                                    onChanged: (val) {
                                      locationViewProvider
                                          .setDestinationPointAddress(val);
                                    },
                                    onTap: () {
                                      locationViewProvider.setLocationView(
                                          LocationView.DESTINATIONSELECTED);
                                    },
                                    controller: _destinationController,
                                    style: TextStyle(
                                        color: ThemeColors.primaryColor,
                                        fontSize: 16.0),
                                    decoration: InputDecoration(
                                        icon: Icon(Octicons.check,
                                            color: Colors.green),
                                        hintText: "Your Drop Location",
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: ThemeColors.primaryColor),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        )),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: <Widget>[
                              if (isSearchingCurrently)
                                _isSearchingOrNotFound(searchVal),
                              if (!isSearchingCurrently)
                                for (LocationDetails detail
                                    in allLocations) ...[
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
                                          mainAddress = detail.locationAddress;
                                          moveCamera(getLatLng);
                                          locationViewProvider.setAddress(
                                              detail.locationAddress);
                                          if (locationViewProvider
                                                  .getLocationView ==
                                              LocationView.PICKUPSELECTED) {
                                            _pickUpController.text =
                                                detail.locationAddress;
                                            locationViewProvider
                                                .setPickUpLatLng(getLatLng);
                                            locationViewProvider
                                                .setPickUpAddress(mainAddress);
                                          } else {
                                            _destinationController.text =
                                                detail.locationAddress;
                                            locationViewProvider
                                                .setDestinationLatLng(
                                                    getLatLng);
                                            locationViewProvider
                                                .setDestinationPointAddress(
                                                    detail.locationAddress);
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
                        ),
                        Column(
                          children: <Widget>[
                            ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: ThemeColors.primaryColor,
                                child: Icon(
                                  Icons.home,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text("Add Home Address"),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: ThemeColors.primaryColor,
                                child: Icon(
                                  Icons.work,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text("Add Office Address"),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: ThemeColors.primaryColor,
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.arrow_forward_ios,
                                    color: Colors.black),
                              ),
                              title: Text("Saved Places"),
                            ),
                            ListTile(
                              onTap: () {
                                if (locationViewProvider.getLocationView ==
                                    LocationView.PICKUPSELECTED) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => DropLocationMap(
                                            dropController: _pickUpController,
                                            initLatLng: initLatLng,
                                          )));
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => DropLocationMap(
                                            dropController:
                                                _destinationController,
                                            initLatLng: initLatLng,
                                          )));
                                }
                              },
                              contentPadding: const EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: ThemeColors.primaryColor,
                                child: Icon(
                                  Icons.map,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text("Pick From Map"),
                            ),
                           
                            ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: ThemeColors.primaryColor,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text("Choose Current Location"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            body: initLatLng == null
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.primaryColor),
                    ),
                  )
                : Stack(
                    children: <Widget>[
                      GoogleMap(
                        buildingsEnabled: true,
                        polylines: _polyLines,
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          zoom: zoomView,
                          target: initLatLng,
                        ),
                        onMapCreated: (controller) {
                          _googleMapController = controller;
                          locationViewProvider.setPickUpLatLng(initLatLng);
                          locationViewProvider.setPickUpAddress(mainAddress);
                        },
                      ),
                      _buildMenu(),
                      _buildMyLocation(),
                      pin(),
                      _buildNotification(),
                    ],
                  ),
          )),
    );
  }

  Widget _buildMyLocation() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height / 2 - 70),
      right: 10.0,
      child: FloatingActionButton(
        heroTag: "my_location_btn_home",
        onPressed: () => _googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
                target: initLatLng, zoom: 18, bearing: 180, tilt: 60))),
        child: Icon(Icons.my_location),
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget _buildSearch(BuildContext context) {
  //   return Positioned(
  //     top: 40,
  //     left: 20,
  //     right: 20,
  //     height: 60,
  //     child: Container(
  //       width: MediaQuery.of(context).size.width,
  //       height: 60.0,
  //       decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(10.0),
  //           color: Colors.white,
  //           boxShadow: [
  //             BoxShadow(color: Colors.grey.shade100, blurRadius: 14.0)
  //           ]),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           IconButton(
  //             icon: Icon(Icons.menu),
  //             onPressed: () => _scaffoldKey.currentState.openDrawer(),
  //             color: ThemeColors.primaryColor,
  //           ),
  //           Expanded(
  //             child: TextField(
  //               focusNode: _mainFocusNode,
  //               onTap: () {
  //                 _mainFocusNode.unfocus();
  //                 _pickFocusNode.requestFocus();
  //                 _controller.open();
  //               },
  //               style:
  //                   TextStyle(color: ThemeColors.primaryColor, fontSize: 16.0),
  //               decoration: InputDecoration(
  //                   filled: true,
  //                   fillColor: Colors.white,
  //                   hintText: "Your Current Location",
  //                   border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide: BorderSide.none)),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMenu() {
    return Positioned(
      top: 35.0,
      left: 10.0,
      child: FloatingActionButton(
        heroTag: "home_menu",
        onPressed: () => _scaffoldKey.currentState.openDrawer(),
        child: Icon(Icons.menu),
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.white,
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
              'asset/images/marker-0.png',
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

  Widget _buildNotification() {
    return Positioned(
      top: 35,
      right: 10.0,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "notification_home",
            onPressed: () => _scaffoldKey.currentState.openDrawer(),
            child: Icon(MaterialIcons.notifications),
            backgroundColor: ThemeColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          SizedBox(
            height: 10.0,
          ),
          FloatingActionButton(
            heroTag: "home_sch",
            onPressed: () {},
            child: Icon(Icons.watch_later),
            backgroundColor: ThemeColors.primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _isSearchingOrNotFound(String result) {
    return Container();
  }

  Widget _renderCollapsed(
      OrderProvider orderProvider, LocationViewProvider locationViewProvider) {
    if (_viewState == ViewState.DEFAULT) {
      return SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isLocalSelected = true;

                            isOutSideSelected = false;

                            zoomView = 18;
                          });

                          orderProvider.setStationView(StationView.LOCAL);

                          _googleMapController.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                            target: initLatLng,
                            zoom: zoomView,
                          )));
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.all(5.0),
                          width: (MediaQuery.of(context).size.width / 2) - 20,
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              border: isLocalSelected
                                  ? Border.all(
                                      color: ThemeColors.primaryColor,
                                      width: 4.0)
                                  : null,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100, blurRadius: 10)
                              ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
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

                            zoomView = 14;
                          });

                          orderProvider.setStationView(StationView.OUTSIDE);

                          _googleMapController.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                            target: initLatLng,
                            zoom: zoomView,
                          )));
                        },
                        child: Container(
                          height: 50,
                          width: (MediaQuery.of(context).size.width / 2) - 20,
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                              border: isOutSideSelected
                                  ? Border.all(
                                      color: ThemeColors.primaryColor,
                                      width: 4.0)
                                  : null,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100, blurRadius: 10)
                              ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "OutStation",
                                style: TextStyle(fontSize: 14.0),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(children: <Widget>[
                    TextField(
                      onChanged: (val) {
                        locationViewProvider.setPickUpAddress(val);
                      },
                      onTap: () {
                        locationViewProvider
                            .setLocationView(LocationView.PICKUPSELECTED);

                        _controller.open();
                      },
                      controller: _pickUpController,
                      focusNode: _pickFocusNode,
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                      readOnly: true,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 8.0),
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
                    // TextField(
                    //   onChanged: (val) {
                    //     locationViewProvider.setDestinationPointAddress(val);
                    //   },
                    //   onTap: () {
                    //     locationViewProvider
                    //         .setLocationView(LocationView.DESTINATIONSELECTED);

                    //     _controller.open();
                    //   },
                    //   controller: _destinationController,
                    //   style: TextStyle(color: Colors.black, fontSize: 16.0),
                    //   readOnly: true,
                    //   decoration: InputDecoration(
                    //       contentPadding: EdgeInsets.symmetric(
                    //           vertical: 2.0, horizontal: 8.0),
                    //       prefixIcon: IconButton(
                    //         icon: Icon(Icons.my_location),
                    //         onPressed: () =>
                    //             _scaffoldKey.currentState.openDrawer(),
                    //         color: ThemeColors.primaryColor,
                    //       ),
                    //       hintText: "Your Drop Location",
                    //       border: OutlineInputBorder(
                    //         borderSide:
                    //             BorderSide(color: ThemeColors.primaryColor),
                    //         borderRadius: BorderRadius.circular(10),
                    //       )),
                    // ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Icon(Icons.star),
                        Text("Choose a Saved Place",
                            style: TextStyle(fontSize: 18)),
                        Icon(Icons.arrow_forward_ios)
                      ],
                    )
                  ]),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 8.0,
              child: FloatingActionButton(
                heroTag: "go_ahead_default",
                onPressed: () {
                  if (orderProvider.getStationView == StationView.LOCAL)
                    setState(() => _viewState = ViewState.LOCALSTATION);
                  else
                    setState(() => _viewState = ViewState.OUTSIDESTATION);
                },
                child: Icon(Icons.arrow_forward_ios),
              ),
            )
          ],
        ),
      );
    } else if (_viewState == ViewState.LOCALSTATION) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          primary: true,
          child: Stack(
            children: [
              Container(
                height: (MediaQuery.of(context).size.height / 2) - 80,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(children: <Widget>[
                        TextField(
                            controller: _pickUpController,
                            focusNode: _pickFocusNode,
                            style:
                                TextStyle(color: Colors.black, fontSize: 16.0),
                            readOnly: true,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(5),
                                icon: Icon(Octicons.primitive_dot,
                                    color: Colors.black38),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none))),
                        SizedBox(
                          height: 15.0,
                        ),
                        TextField(
                            controller: _destinationController,
                            style:
                                TextStyle(color: Colors.black, fontSize: 16.0),
                            readOnly: true,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(5),
                                icon: Icon(
                                  Octicons.check,
                                  color: ThemeColors.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none))),
                        SizedBox(height: 10.0),
                        TextField(
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 8.0),
                              hintText: "Package weight (In KG)",
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: ThemeColors.primaryColor),
                                borderRadius: BorderRadius.circular(10),
                              )),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TruckCategory(
                              onTap: () {
                                print('CLICKED');
                              },
                              elevation: 30.0,
                              btnContext: context,
                              backgroundColor: ThemeColors.primaryColor,
                              foregroundColor: Colors.white,
                              text: Text("Mini"),
                              borderColor: Colors.transparent,
                            ),
                            TruckCategory(
                              onTap: () {},
                              btnContext: context,
                              backgroundColor: ThemeColors.primaryColor,
                              foregroundColor: Colors.white,
                              text: Text("Small"),
                              borderColor: Colors.transparent,
                            )
                          ],
                        ),
                        TruckCategory(
                          onTap: () {},
                          btnContext: context,
                          backgroundColor: ThemeColors.primaryColor,
                          foregroundColor: Colors.white,
                          text: Text("Medium"),
                          borderColor: Colors.transparent,
                        )
                      ]),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10.0,
                left: 8.0,
                child: FloatingActionButton(
                  heroTag: "go_back_default",
                  onPressed: () =>
                      setState(() => _viewState = ViewState.DEFAULT),
                  child: Icon(Icons.arrow_back_ios),
                ),
              ),
              Positioned(
                bottom: 10.0,
                right: 8.0,
                child: FloatingActionButton(
                  heroTag: "go_ahead_truck",
                  onPressed: () =>
                      setState(() => _viewState = ViewState.TRUCKVIEW),
                  child: Icon(Icons.arrow_forward_ios),
                ),
              )
            ],
          ),
        ),
      );
    } else if (_viewState == ViewState.OUTSIDESTATION) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          primary: true,
          child: Stack(
            children: [
              Container(
                height: (MediaQuery.of(context).size.height / 2) - 80,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Column(children: <Widget>[
                        TextField(
                            controller: _pickUpController,
                            focusNode: _pickFocusNode,
                            style:
                                TextStyle(color: Colors.black, fontSize: 16.0),
                            readOnly: true,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(5),
                                icon: Icon(Octicons.primitive_dot,
                                    color: Colors.black38),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none))),
                        SizedBox(
                          height: 15.0,
                        ),
                        TextField(
                            controller: _destinationController,
                            style:
                                TextStyle(color: Colors.black, fontSize: 16.0),
                            readOnly: true,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(5),
                                icon: Icon(
                                  Octicons.check,
                                  color: ThemeColors.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none))),
                        SizedBox(
                          height: 5.0,
                        ),
                        TextField(
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: "Your Estimated Price",
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: ThemeColors.primaryColor),
                                borderRadius: BorderRadius.circular(10),
                              )),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TruckCategory(
                              onTap: () {
                                print('CLICKED');
                              },
                              elevation: 30.0,
                              btnContext: context,
                              backgroundColor: ThemeColors.primaryColor,
                              foregroundColor: Colors.white,
                              text: Text("Small"),
                              borderColor: Colors.transparent,
                            ),
                            TruckCategory(
                              onTap: () {},
                              btnContext: context,
                              backgroundColor: ThemeColors.primaryColor,
                              foregroundColor: Colors.white,
                              text: Text("Medium"),
                              borderColor: Colors.transparent,
                            )
                          ],
                        ),
                        TruckCategory(
                          onTap: () {},
                          btnContext: context,
                          backgroundColor: ThemeColors.primaryColor,
                          foregroundColor: Colors.white,
                          text: Text("Large"),
                          borderColor: Colors.transparent,
                        )
                      ])),
                ]),
              ),
              Positioned(
                bottom: 10.0,
                left: 8.0,
                child: FloatingActionButton(
                  heroTag: "go_back_default",
                  onPressed: () =>
                      setState(() => _viewState = ViewState.DEFAULT),
                  child: Icon(Icons.arrow_back_ios),
                ),
              ),
              Positioned(
                bottom: 10.0,
                right: 8.0,
                child: FloatingActionButton(
                  heroTag: "go_ahead_truck",
                  onPressed: () =>
                      setState(() => _viewState = ViewState.TRUCKVIEW),
                  child: Icon(Icons.arrow_forward_ios),
                ),
              )
            ],
          ),
        ),
      );
    } else if (_viewState == ViewState.TRUCKVIEW) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Stack(children: [
            Center(
              child: SingleChildScrollView(
                child: Column(children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 120,
                      width: MediaQuery.of(context).size.width - 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(
                              color: ThemeColors.primaryColor, width: 5.0)),
                      child: Row(
                        children: [
                          Container(
                              height: 100,
                              width: 100,
                              child: Image.asset('asset/images/newlogo.png')),
                          Text('Name of Truck 1'),
                          Text("Price = 123"),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 120,
                      width: MediaQuery.of(context).size.width - 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(
                              color: Colors.transparent, width: 5.0)),
                      child: Row(
                        children: [
                          Container(
                              height: 100,
                              width: 100,
                              child: Image.asset('asset/images/newlogo.png')),
                          Text('Name of Truck 1'),
                          Text("Price = 123"),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 120,
                      width: MediaQuery.of(context).size.width - 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(
                              color: Colors.transparent, width: 5.0)),
                      child: Row(
                        children: [
                          Container(
                              height: 100,
                              width: 100,
                              child: Image.asset('asset/images/newlogo.png')),
                          Text('Name of Truck 1'),
                          Text("Price = 123"),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 120,
                      width: MediaQuery.of(context).size.width - 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          border: Border.all(
                              color: Colors.transparent, width: 5.0)),
                      child: Row(
                        children: [
                          Container(
                              height: 100,
                              width: 100,
                              child: Image.asset('asset/images/newlogo.png')),
                          Text('Name of Truck 1'),
                          Text("Price = 123"),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Positioned(
              bottom: 10.0,
              left: 8.0,
              child: FloatingActionButton(
                heroTag: "go_back_default",
                onPressed: () =>
                    setState(() => _viewState = ViewState.LOCALSTATION),
                child: Icon(Icons.arrow_back_ios),
              ),
            ),
            Positioned(
              bottom: 10.0,
              right: 8.0,
              child: FloatingActionButton(
                heroTag: "go_ahead_truck",
                onPressed: () {},
                child: Icon(Icons.arrow_forward_ios),
              ),
            )
          ]),
        ),
      );
    }
  }
}
