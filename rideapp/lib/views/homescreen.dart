import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
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
  final String SEARCHING_LOCATIONS = "Searching locations...";
  final String NOT_FOUND = "No result found";
  GlobalKey<FormState> _locationForm = GlobalKey<FormState>();
  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: APIKeys.googleMapsAPI);
  int price;
  bool isShowMarker = true;
  Set<Marker> _markers = {};

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
    if (_pickUpController.text.isEmpty) {
      setState(() {
        isSearchingCurrently = false;
        searchVal = "Searchdone";
      });
    }
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
    if (_destinationController.text.isEmpty) {
      print("Hello");
      allLocations.clear();
      setState(() {
        isSearchingCurrently = false;
        searchVal = "Searchdone";
      });
    }
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
          setState(() {
            isSearchingCurrently = false;
            searchVal = "Searchdone";
          });
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

  Future<List<LatLng>> getPolylinePoints(LocationViewProvider provider) async {
    return await _googleMapPolyline.getCoordinatesWithLocation(
        origin: provider.getPickUpLatLng,
        destination: provider.getDestinationLatLng,
        mode: RouteMode.driving);
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
                  onTap: () => Navigator.pushNamed(context, '/allordersscreen'),
                  leading:
                      Icon(Icons.event_note, color: ThemeColors.primaryColor),
                  title: Text(
                    "All Bookings",
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
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                  leading: Icon(Icons.notifications,
                      color: ThemeColors.primaryColor),
                  title: Text(
                    "Notifications",
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
                _pickUpController.text =
                    locationViewProvider.getPickUpPointAddress;
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
                    child: Stack(
                      children: [
                        Column(
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
                                      Form(
                                        key: _locationForm,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              validator: (val) {
                                                if (val.length <= 5) {
                                                  return "Enter a valid address";
                                                }
                                              },
                                              onChanged: (val) {
                                                if (val.isEmpty) {
                                                  setState(() {
                                                    searchVal = "Searchdone";

                                                    isSearchingCurrently =
                                                        false;
                                                  });

                                                  locationViewProvider
                                                      .setPickUpAddress(val);
                                                } else {
                                                  locationViewProvider
                                                      .setPickUpAddress(val);
                                                }
                                              },
                                              onTap: () {
                                                locationViewProvider
                                                    .setLocationView(
                                                        LocationView
                                                            .PICKUPSELECTED);
                                              },
                                              controller: _pickUpController,
                                              focusNode: _pickFocusNode,
                                              style: TextStyle(
                                                  color:
                                                      ThemeColors.primaryColor,
                                                  fontSize: 16.0),
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                  icon: Icon(
                                                      Octicons.primitive_dot,
                                                      color: Colors.green),
                                                  hintText:
                                                      "Your Pickup Location",
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: ThemeColors
                                                            .primaryColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  )),
                                            ),
                                            SizedBox(height: 10.0),
                                            TextFormField(
                                              validator: (val) {
                                                if (val.length <= 5) {
                                                  return "Enter a valid address";
                                                }
                                              },
                                              focusNode: _dropFocusNode,
                                              onChanged: (val) {
                                                if (val.isEmpty) {
                                                  setState(() {
                                                    searchVal = "Searchdone";

                                                    isSearchingCurrently =
                                                        false;
                                                  });

                                                  locationViewProvider
                                                      .setDestinationPointAddress(
                                                          val);
                                                } else {
                                                  locationViewProvider
                                                      .setDestinationPointAddress(
                                                          val);
                                                }
                                              },
                                              onTap: () {
                                                locationViewProvider
                                                    .setLocationView(LocationView
                                                        .DESTINATIONSELECTED);
                                              },
                                              controller:
                                                  _destinationController,
                                              style: TextStyle(
                                                  color:
                                                      ThemeColors.primaryColor,
                                                  fontSize: 16.0),
                                              decoration: InputDecoration(
                                                  icon: Icon(
                                                      Octicons.primitive_dot,
                                                      color: Colors.red),
                                                  hintText:
                                                      "Your Drop Location",
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: ThemeColors
                                                            .primaryColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  )),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            if (_destinationController.text.isNotEmpty ||
                                _pickUpController.text.isNotEmpty)
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
                                                mainAddress =
                                                    detail.locationAddress;

                                                moveCamera(getLatLng);

                                                locationViewProvider.setAddress(
                                                    detail.locationAddress);

                                                if (locationViewProvider
                                                        .getLocationView ==
                                                    LocationView
                                                        .PICKUPSELECTED) {
                                                  _pickUpController.text =
                                                      detail.locationAddress;

                                                  locationViewProvider
                                                      .setPickUpLatLng(
                                                          getLatLng);

                                                  locationViewProvider
                                                      .setPickUpAddress(
                                                          mainAddress);
                                                } else {
                                                  _destinationController.text =
                                                      detail.locationAddress;

                                                  locationViewProvider
                                                      .setDestinationLatLng(
                                                          getLatLng);

                                                  locationViewProvider
                                                      .setDestinationPointAddress(
                                                          detail
                                                              .locationAddress);
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
                            if (_destinationController.text.isEmpty ||
                                _pickUpController.text.isEmpty)
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
                                      if (locationViewProvider
                                              .getLocationView ==
                                          LocationView.PICKUPSELECTED) {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DropLocationMap(
                                                      dropController:
                                                          _pickUpController,
                                                      initLatLng: initLatLng,
                                                    )));
                                      } else {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DropLocationMap(
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
                        Positioned(
                          bottom: 0.0,
                          right: 0.0,
                          child: FloatingActionButton(
                            child: Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              if (_locationForm.currentState.validate()) {
                                if (orderProvider.getStationView ==
                                    StationView.LOCAL) {
                                  setState(() {
                                    _viewState = ViewState.LOCALSTATION;
                                  });
                                  _controller.close();
                                } else {
                                  setState(() {
                                    _viewState = ViewState.OUTSIDESTATION;
                                  });
                                  _controller.close();
                                }
                              }
                            },
                          ),
                        )
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
                        markers: _markers,
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
                      if (isShowMarker) pin(),
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
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            child: Icon(MaterialIcons.notifications),
            backgroundColor: ThemeColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          SizedBox(
            height: 10.0,
          ),
          FloatingActionButton(
            heroTag: "home_sch",
            onPressed: () async{
              await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 30)));
              await showTimePicker(context: context, initialTime: TimeOfDay.now());
            },
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
            Container(
              height: MediaQuery.of(context).size.height / 2 - 100,
              width: MediaQuery.of(context).size.width,
            ),
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
                              color: isLocalSelected
                                  ? Colors.blue[300]
                                  : Colors.white,
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
                              color: isOutSideSelected
                                  ? Colors.blue[300]
                                  : Colors.white,
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
                            icon: Icon(
                              Icons.my_location,
                              color: Colors.green,
                            ),
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
                        locationViewProvider
                            .setLocationView(LocationView.DESTINATIONSELECTED);

                        _controller.open();
                      },
                      controller: _destinationController,
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                      readOnly: true,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 8.0),
                          prefixIcon: IconButton(
                            icon: Icon(
                              Icons.my_location,
                              color: Colors.red,
                            ),
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
                  ]),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 8.0,
              child: FlatButton(
                // heroTag: "go_ahead_default",
                onPressed: () async {
                  if (_pickUpController.text.length > 5 &&
                      _destinationController.text.length > 5) {
                    List<LatLng> allLats =
                        await getPolylinePoints(locationViewProvider);
                    setState(() {
                      isShowMarker = false;
                      _markers.add(Marker(
                        markerId: MarkerId('pickmakrer'),
                        visible: true,
                        draggable: false,
                        position: locationViewProvider.getPickUpLatLng,
                        icon: BitmapDescriptor.defaultMarker,
                      ));
                      _markers.add(Marker(
                        markerId: MarkerId('dropMarker'),
                        visible: true,
                        draggable: false,
                        position: locationViewProvider.getDestinationLatLng,
                        icon: BitmapDescriptor.defaultMarker,
                      ));
                      _polyLines.add(Polyline(
                          polylineId: PolylineId('main'),
                          color: ThemeColors.primaryColor,
                          width: 10,
                          endCap: Cap.buttCap,
                          startCap: Cap.roundCap,
                          jointType: JointType.round,
                          points: allLats,
                          visible: true));
                    });
                    _googleMapController.moveCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                      target: locationViewProvider.getPickUpLatLng,
                      zoom: 10,
                    )));

                    if (orderProvider.getStationView == StationView.LOCAL)
                      setState(() => _viewState = ViewState.LOCALSTATION);
                    else
                      setState(() => _viewState = ViewState.OUTSIDESTATION);
                  } else {
                    _controller.open();
                  }
                },
                child: Row(
                  children: <Widget>[
                    Text(
                      "Next",
                      style: TextStyle(fontSize: 15),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ThemeColors.primaryColor,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    } else if (_viewState == ViewState.LOCALSTATION) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        primary: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Stack(
            children: [
              Container(
                height: (MediaQuery.of(context).size.height / 2) - 100,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      child: Column(children: <Widget>[
                        Container(
                          height: 80,
                          padding:
                              EdgeInsets.only(top: 10.0, right: 10, left: 10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Octicons.primitive_dot,
                                      color: Colors.green),
                                  SizedBox(width: 10.0),
                                  Text(
                                    _pickUpController.text,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 05.0,
                              ),
                              Row(
                                children: [
                                  Icon(Octicons.primitive_dot,
                                      color: Colors.red),
                                  SizedBox(width: 10.0),
                                  Text(
                                    _destinationController.text,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.0),
                        // TextField(
                        //   style: TextStyle(color: Colors.black, fontSize: 16.0),
                        //   keyboardType: TextInputType.number,
                        //   decoration: InputDecoration(
                        //       contentPadding: EdgeInsets.symmetric(
                        //           vertical: 2.0, horizontal: 8.0),
                        //       hintText: "Package weight (In KG)",
                        //       border: OutlineInputBorder(
                        //         borderSide:
                        //             BorderSide(color: ThemeColors.primaryColor),
                        //         borderRadius: BorderRadius.circular(10),
                        //       )),
                        // ),
                        // SizedBox(
                        //   height: 10.0,
                        // ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                            child: Text("Select Truck Category"),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 50,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            onChanged: (String value) {
                              orderProvider.setTruckCategoryLocal(value);
                            },
                            elevation: 5,
                            value: orderProvider.getSelectedTruckLocal,
                            items: orderProvider.getTruckCatLocal
                                .map((String truck) {
                              return DropdownMenuItem(
                                value: truck,
                                child: Text(truck),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                child: FlatButton(
                  // heroTag: "go_back_default",
                  onPressed: () => setState(() {
                    _viewState = ViewState.DEFAULT;
                    isShowMarker = true;
                  }),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.arrow_back_ios),
                      Text(
                        "Back",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: FlatButton(
                  onPressed: () =>
                      setState(() => _viewState = ViewState.TRUCKVIEW),
                  child: Row(
                    children: <Widget>[
                      Text(
                        "Next",
                        style: TextStyle(fontSize: 15),
                      ),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else if (_viewState == ViewState.OUTSIDESTATION) {
      return SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
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
                            horizontal: 20.0, vertical: 0.0),
                        child: Column(children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: 80,
                              padding: EdgeInsets.only(
                                  top: 10.0, right: 10, left: 10),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10.0),
                                // boxShadow: [
                                //   BoxShadow(
                                //       color: Colors.grey.shade100,
                                //       blurRadius: 10.0,
                                //       spreadRadius: 5.0)
                                // ]
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Octicons.primitive_dot,
                                          color: Colors.green),
                                      SizedBox(width: 10.0),
                                      Text(
                                        _pickUpController.text,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 05.0,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Octicons.primitive_dot,
                                          color: Colors.red),
                                      SizedBox(width: 10.0),
                                      Text(
                                        _destinationController.text,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          TextField(
                            style:
                                TextStyle(color: Colors.black, fontSize: 16.0),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                hintText: "Your Estimated Price",
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ThemeColors.primaryColor),
                                  borderRadius: BorderRadius.circular(10),
                                )),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                              child: Text("Select Truck Category"),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 50,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              onChanged: (String value) {
                                setState(() {
                                  orderProvider.setTruckCategory(value);
                                });
                              },
                              elevation: 5,
                              value: orderProvider.getSelectedTruck,
                              items: orderProvider.getTruckCategory
                                  .map((String truck) {
                                return DropdownMenuItem(
                                  value: truck,
                                  child: Text(truck),
                                );
                              }).toList(),
                            ),
                          ),
                        ])),
                  ]),
                ),
                Positioned(
                  bottom: 35.0,
                  left: 8.0,
                  child: FlatButton(
                    // heroTag: "go_back_default",
                    onPressed: () => setState(() {
                      _viewState = ViewState.DEFAULT;
                      isShowMarker = true;
                    }),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.arrow_back_ios),
                        Text(
                          "Back",
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35.0,
                  right: 8.0,
                  child: FlatButton(
                    // heroTag: "go_ahead_truck",
                    onPressed: () =>
                        setState(() => _viewState = ViewState.TRUCKVIEW),
                    child: Row(
                      children: <Widget>[
                        Text(
                          "Next",
                          style: TextStyle(fontSize: 15),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } else if (_viewState == ViewState.TRUCKVIEW) {
      return SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            primary: true,
            child: Stack(children: [
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height / 2 - 100,
                  child: StreamBuilder(
                    stream: Firestore.instance
                        .collection('trucks')
                        .where("category",
                            isEqualTo: _viewState == ViewState.LOCALSTATION
                                ? orderProvider.getSelectedTruckLocal
                                : orderProvider.getSelectedTruck)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeColors.primaryColor),
                        ));
                      } else {
                        if (snapshot.data.documents.length == 0) {
                          return Center(
                              child: Text("No Trucks of this category !"));
                        }
                        return ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          primary: true,
                          physics: AlwaysScrollableScrollPhysics(),
                          children: snapshot.data.documents
                              .map((DocumentSnapshot truck) {
                              int priceDemo =   orderProvider.getOrderPrice;
                            int priceDemo0 = truck.data['priceFactor'] * 5;
                            return InkWell(
                              onTap: () {
                                setState(() => price = priceDemo);
                                orderProvider.setTruckName(truck.data['name']);
                              },
                              child: Container(
                                  height: 110,
                                  width:
                                      (MediaQuery.of(context).size.width / 3) +
                                          30,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: orderProvider.getTruckName ==
                                                  truck.data['name']
                                              ? ThemeColors.primaryColor
                                              : Colors.white,
                                          style: BorderStyle.solid,
                                          width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 10,
                                            color: Colors.grey.shade100,
                                            spreadRadius: 4.0)
                                      ]),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  child: Container(
                                    child: Row(
                                      children: <Widget>[
                                        CachedNetworkImage(
                                          imageBuilder: (context, provider) {
                                            return Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                height: 100,
                                                width: 100,
                                                child: Image(
                                                    image: provider,
                                                    height: 100,
                                                    width: 100));
                                          },
                                          imageUrl: truck.data['image'],
                                          placeholder: (context, str) {
                                            return Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              height: 100,
                                              width: 100,
                                              child: Image.asset(
                                                  'asset/images/newlogo.png'),
                                            );
                                          },
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: <Widget>[
                                                Text(
                                                  truck.data['name'],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14.0),
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  "20 min away",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14.0),
                                                ),
                                              ],
                                            ),
                                            
                                             Text(
                                                  "Capacity: 1000KG",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14.0),
                                                ),
                                                Text(
                                              "Estimated Fare :  ₹ $priceDemo",
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 18.0),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 20.0,
                left: 8.0,
                child: FlatButton(
                  // heroTag: "go_back_default",
                  onPressed: () {
                    if (orderProvider.getStationView == StationView.LOCAL)
                      setState(() => _viewState = ViewState.LOCALSTATION);
                    else {
                      setState(() => _viewState = ViewState.OUTSIDESTATION);
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.arrow_back_ios),
                      Text(
                        "Back",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20.0,
                right: 8.0,
                child: FlatButton(
                  // heroTag: "go_ahead_truck",
                  onPressed: () {
                    print(price);
                    if (price == null) {
                      Fluttertoast.showToast(msg: "Please select a truck");
                    } else {
                      orderProvider.setOrderPrice(locationViewProvider, price);
                      Navigator.pushNamed(context, '/orderdetailsscreen');
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      Text(
                        "Next",
                        style: TextStyle(fontSize: 15),
                      ),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              )
            ]),
          ),
        ),
      );
    } else if (true == false) {
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
