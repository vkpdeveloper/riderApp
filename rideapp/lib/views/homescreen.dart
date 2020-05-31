import 'dart:async';
import 'dart:convert';

import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/apikeys.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/static_utils.dart';
import 'package:rideapp/enums/locationview.dart';
import 'package:rideapp/model/auto_complete_item.dart';
import 'package:rideapp/model/nearby_places.dart';
import 'package:rideapp/providers/locationViewProvider.dart';
import 'package:rideapp/providers/orderprovider.dart';
import 'package:rideapp/providers/user_provider.dart';
import 'package:rideapp/services/firebase_auth_service.dart';
import 'package:rideapp/utils/uuid.dart';
import 'package:rideapp/views/saveaddress_screen.dart';
import 'package:rideapp/widgets/rich_suggestion.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;

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
  String sessionToken;

  OverlayEntry overlayEntry;
  List<NearbyPlace> nearbyPlaces = List();
  var appBarKey = GlobalKey();
  LocationResult locationResult;
  bool hasSearchTerm = false;
  LatLng _lastMapPos;
  final _searchQuery = new TextEditingController();
  Timer _debounce;
  FocusNode _searchQueryNode;
  bool isFirstTimeOpen = true;

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_searchQuery.text);
    });
  }

  void clearOverlay() {
    if (overlayEntry != null) {
      overlayEntry.remove();
      overlayEntry = null;
    }
  }

  void searchPlace(String place) {
    if (_scaffoldKey.currentContext == null) return;

    clearOverlay();

    setState(() => hasSearchTerm = place.length > 0);

    if (place.length < 1) return;

    final RenderBox renderBox = _scaffoldKey.currentContext.findRenderObject();
    Size size = renderBox.size;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 160,
        width: MediaQuery.of(context).size.width,
        child: Material(
          elevation: 1,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'Finding place...',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    autoCompleteSearch(place);
  }

  void autoCompleteSearch(String place) {
    place = place.replaceAll(" ", "+");
    var endpoint =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "key=${APIKeys.googleMapsAPI}&" +
            "input={$place}&sessiontoken=$sessionToken";

    if (locationResult != null) {
      endpoint += "&location=${locationResult.latLng.latitude}," +
          "${locationResult.latLng.longitude}";
    }
    LocationUtils.getAppHeaders()
        .then((headers) => http.get(endpoint, headers: headers))
        .then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(data);
        List<dynamic> predictions = data['predictions'];

        List<RichSuggestion> suggestions = [];

        if (predictions.isEmpty) {
          AutoCompleteItem aci = AutoCompleteItem();
          aci.text = 'No result found';
          aci.offset = 0;
          aci.length = 0;

          suggestions.add(RichSuggestion(aci, () {}));
        } else {
          for (dynamic t in predictions) {
            AutoCompleteItem aci = AutoCompleteItem();

            aci.id = t['place_id'];
            aci.text = t['description'];
            aci.offset = t['matched_substrings'][0]['offset'];
            aci.length = t['matched_substrings'][0]['length'];

            suggestions.add(RichSuggestion(aci, () {
              decodeAndSelectPlace(aci.id);
            }));
          }
        }

        displayAutoCompleteSuggestions(suggestions);
      }
    }).catchError((error) {
      print("Error : ${error}");
    });
  }

  void decodeAndSelectPlace(String placeId) {
    clearOverlay();

    String endpoint =
        "https://maps.googleapis.com/maps/api/place/details/json?key=${APIKeys.googleMapsAPI}" +
            "&placeid=$placeId";

    LocationUtils.getAppHeaders()
        .then((headers) => http.get(endpoint, headers: headers))
        .then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> location =
            jsonDecode(response.body)['result']['geometry']['location'];

        LatLng latLng = LatLng(location['lat'], location['lng']);

        moveToLocation(latLng);
      }
    }).catchError((error) {
      print(error);
    });
  }

  void moveToLocation(LatLng latLng) {
    _searchQueryNode.unfocus();
    _mapsController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: 16,
        ),
      ),
    );

    clearOverlay();

    reverseGeocodeLatLng(latLng);

    getNearbyPlaces(latLng);
  }

  void getNearbyPlaces(LatLng latLng) {
    LocationUtils.getAppHeaders()
        .then((headers) => http.get(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json?" +
                "key=${APIKeys.googleMapsAPI}&" +
                "location=${latLng.latitude},${latLng.longitude}&radius=150",
            headers: headers))
        .then((response) {
      if (response.statusCode == 200) {
        nearbyPlaces.clear();
        for (Map<String, dynamic> item
            in jsonDecode(response.body)['results']) {
          NearbyPlace nearbyPlace = NearbyPlace();

          nearbyPlace.name = item['name'];
          nearbyPlace.icon = item['icon'];
          double latitude = item['geometry']['location']['lat'];
          double longitude = item['geometry']['location']['lng'];

          LatLng _latLng = LatLng(latitude, longitude);

          nearbyPlace.latLng = _latLng;

          nearbyPlaces.add(nearbyPlace);
        }
      }
      setState(() {
        hasSearchTerm = false;
      });
    }).catchError((error) {});
  }

  Future reverseGeocodeLatLng(LatLng latLng) async {
    var response = await http.get(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}"
        "&key=${APIKeys.googleMapsAPI}",
        headers: await LocationUtils.getAppHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);

      String road;

      if (responseJson['status'] == 'REQUEST_DENIED') {
        road = 'REQUEST DENIED = please see log for more details';
        print(responseJson['error_message']);
      } else {
        road =
            responseJson['results'][0]['address_components'][0]['short_name'];
      }

      setState(() {
        locationResult = LocationResult();
        locationResult.address = road;
        locationResult.latLng = latLng;
      });
    }
  }

  void displayAutoCompleteSuggestions(List<RichSuggestion> suggestions) {
    final RenderBox renderBox = _scaffoldKey.currentContext.findRenderObject();
    Size size = renderBox.size;

    clearOverlay();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        top: 160,
        child: Material(
          elevation: 1,
          child: Column(
            children: suggestions,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _searchQuery.addListener(_onSearchChanged);
    sessionToken = Uuid().generateV4();
    _searchQueryNode = FocusNode();
    _utils.getBytesFromAsset('asset/images/marker.png', 64).then((value) {
      pinLocationIcon = BitmapDescriptor.fromBytes(value);
    });
  }

  void dispose() {
    super.dispose();
    _searchQueryNode.dispose();
    _searchQuery.removeListener(_onSearchChanged);
    _searchQuery.dispose();
  }

  showCurrentLocationOnSheet(LocationViewProvider provider) async {
    final Coordinates coordinates =
        Coordinates(initLatLng.latitude, initLatLng.longitude);
    List<Address> address =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    provider.setAddress(address[0].addressLine);
  }

  getCurrentLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      setState(() {
        initLatLng = LatLng(position.latitude, position.longitude);
      });
    }).catchError((e) {
      print(e);
    });
  }

  showStationPickerDialog(BuildContext context) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          OrderProvider orderProvider = Provider.of<OrderProvider>(context);
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Done"),
                    textColor: ThemeColors.primaryColor)
              ],
              title: Text("Select Ride Type"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile(
                    groupValue: orderProvider.getRideType,
                    value: 0,
                    activeColor: ThemeColors.primaryColor,
                    title: Text("Local"),
                    onChanged: (val) {
                      orderProvider.setGroupRideType(val);
                    },
                  ),
                  RadioListTile(
                    groupValue: orderProvider.getRideType,
                    value: 1,
                    activeColor: ThemeColors.primaryColor,
                    title: Text("Outside Station"),
                    onChanged: (val) {
                      orderProvider.setGroupRideType(val);
                    },
                  )
                ],
              ));
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
                            locationViewProvider.getPickUpPointAddress == "" ||
                                    locationViewProvider
                                            .getPickUpPointAddress ==
                                        null
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
        margin: EdgeInsets.all(20.0),
        borderRadius: BorderRadius.circular(15.0),
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
                                                      "" ||
                                                  locationViewProvider
                                                          .getPickUpPointAddress ==
                                                      null
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
                                                              .getDestinationPointAddress
                                                              .toString() ==
                                                          null ||
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
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SavedAddress(
                                                          isFromHome: true,
                                                        )));
                                            locationViewProvider
                                                .setLocationView(LocationView
                                                    .DESTINATIONSELECTED);
                                          },
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
        body: GestureDetector(
          onTap: () {
            Focus.of(context).unfocus();
            clearOverlay();
          },
          child: Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              initLatLng != null
                  ? Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: GoogleMap(
                        // markers: _markers,
                        // onTap: (LatLng newPosition) async {
                        //   if (_markers.isNotEmpty) {
                        //     _markers.clear();
                        //   }
                        //   _markers.add(Marker(
                        //       markerId: MarkerId("1"),
                        //       position: newPosition,
                        //       icon: pinLocationIcon));
                        //   setState(() {
                        //     initLatLng = newPosition;
                        //   });
                        //   final Coordinates coordinates = Coordinates(
                        //       newPosition.latitude, newPosition.longitude);
                        //   locationViewProvider.setAddress("Fetching...");
                        //   String myAddress =
                        //       await _utils.getAddressOnCords(coordinates);
                        //   locationViewProvider.setAddress(myAddress);
                        //   if (locationViewProvider.getLocationView ==
                        //       LocationView.PICKUPSELECTED)
                        //     locationViewProvider.setPickUpLatLng(newPosition);
                        //   else
                        //     locationViewProvider
                        //         .setDestinationLatLng(newPosition);
                        // },
                        onCameraMove: (CameraPosition position) {
                          _lastMapPos = position.target;
                        },
                        onCameraIdle: () async {
                          if (isFirstTimeOpen) {
                            showCurrentLocationOnSheet(locationViewProvider);
                            isFirstTimeOpen = false;
                          } else {
                            try {
                              print(_lastMapPos);
                              locationViewProvider.setMapLastPos(_lastMapPos);
                              locationViewProvider.setAddress("");
                              Coordinates coordinates = new Coordinates(
                                  _lastMapPos.latitude, _lastMapPos.longitude);
                              List<Address> addresses = await Geocoder.local
                                  .findAddressesFromCoordinates(coordinates);
                              String address = addresses[0].addressLine;
                              if (locationViewProvider.getLocationView ==
                                  LocationView.PICKUPSELECTED) {
                                locationViewProvider
                                    .setPickUpLatLng(locationResult.latLng);

                                locationViewProvider.setPickUpAddress(address);
                              } else {
                                locationViewProvider.setDestinationLatLng(
                                    locationResult.latLng);
                                locationViewProvider
                                    .setDestinationPointAddress(address);
                              }
                            } catch (e) {
                              print(e.toString());
                            }
                          }
                        },
                        myLocationEnabled: true,
                        buildingsEnabled: true,
                        scrollGesturesEnabled: true,
                        mapType: MapType.hybrid,
                        trafficEnabled: true,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        initialCameraPosition: CameraPosition(
                            target: initLatLng,
                            zoom: orderProvider.getRideType == 0 ? 14 : 8),
                        onMapCreated: (GoogleMapController controller) {
                          _mapsController = controller;
                          showCurrentLocationOnSheet(locationViewProvider);
                          locationViewProvider.setPickUpLatLng(initLatLng);
                          showStationPickerDialog(context);
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
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onPressed: () => _scaffoldKey.currentState.openDrawer(),
                  backgroundColor: ThemeColors.primaryColor,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.menu),
                ),
              ),
              Positioned(
                top: 30.0,
                right: 20.0,
                child: FloatingActionButton(
                  heroTag: 'current',
                  onPressed: () {
                    _mapsController.animateCamera(
                        CameraUpdate.newCameraPosition(
                            CameraPosition(target: initLatLng, zoom: 14.0)));
                  },
                  backgroundColor: ThemeColors.primaryColor,
                  foregroundColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: Icon(Icons.my_location),
                ),
              ),
              _buildSearchBar(context),
              pin()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
        top: 100,
        left: 40,
        right: 40,
        child: Container(
          width: MediaQuery.of(context).size.width - 80,
          height: 150,
          child: TextField(
            focusNode: _searchQueryNode,
            controller: _searchQuery,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: "Search Location"),
          ),
        ));
  }

  Widget pin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.place, size: 56),
            Container(
              decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black38,
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
}
