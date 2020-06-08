import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps/flutter_google_maps.dart';
import 'package:flutter_google_maps/flutter_google_maps.dart' as map;
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:riderappweb/constants/apikeys.dart';
import 'package:riderappweb/constants/themecolors.dart';
import 'package:riderappweb/enums/devices_view.dart';
import 'package:riderappweb/model/location_details.dart';
import 'package:riderappweb/model/location_result.dart';
import 'package:riderappweb/utils/uuid.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GeoCoord initPos;
  final double ZOOM_VIEW = 18;
  String currentAddress;
  TextEditingController _locationController = TextEditingController();
  bool isArrowClicked = false;
  DeviceView deviceView;
  Timer _debounce;
  bool hasSearchTerm = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String sessionToken = Uuid().generateV4();
  List<LocationDetails> allLocations = [];
  LocationResult locationResult;

  getCurrentLocation() async {
    LocationData locData = await Location.instance.getLocation();
    setState(() {
      initPos = GeoCoord(locData.latitude, locData.longitude);
    });
    getLocationAddress();
  }

  getLocationAddress() async {
    Response res = await get(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${initPos.latitude},${initPos.longitude}&key=${APIKeys.googleMapsAPI}');
    var data = jsonDecode(res.body);
    currentAddress = data['results'][0]['formatted_address'];
    _locationController.text = currentAddress;
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    // _locationController.addListener(_onSearchChanged);
  }

  // _onSearchChanged() {
  //   if (_debounce?.isActive ?? false) _debounce.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 500), () {
  //     searchPlace(_locationController.text);
  //   });
  // }

  void searchPlace(String place) {
    print(place);

    setState(() => hasSearchTerm = place.length > 0);

    if (place.length < 1) return;

    setState(() {});

    autoCompleteSearch(place);
  }

  void autoCompleteSearch(String place) async {
    print("I am in autocomplete");
    print(sessionToken);
    place = place.replaceAll(" ", "+");
    Response data =
        await get('https://jsonplaceholder.typicode.com/todos/1', headers: {
      "Accept": "application/json",
      "Access-Control-Allow-Origin": "*"
    });
    print(data.statusCode);
    var endpoint =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "key=${APIKeys.googleMapsAPI}&" +
            "input={$place}&sessiontoken=$sessionToken";

    if (locationResult != null) {
      endpoint += "&location=${locationResult.latLng.latitude}," +
          "${locationResult.latLng.longitude}";
    }
    get(endpoint, headers: {"Accept": "application/json"}).then((response) {
      print(response.body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var predictions = data['predictions'];
        allLocations.clear();
        if (predictions.isEmpty) {
          // setState(() => searchVal = "No result found");
        } else {
          for (dynamic single in predictions) {
            print(single);
            LocationDetails detail = LocationDetails(
                locationAddress: single['description'],
                locationID: single['place_id']);
            allLocations.add(detail);
          }
          // setState(() => isSearchingCurrently = false);
        }
      }
    }).catchError((e) => [print(e)]);
  }

  @override
  Widget build(BuildContext context) {
    checkDevice() {
      print("Hello World");
      if (MediaQuery.of(context).size.width <= 700) {
        setState(() {
          deviceView = DeviceView.MOBILE;
        });
      } else {
        deviceView = DeviceView.WEB;
      }
    }

    checkDevice();

    return Scaffold(
      body: Stack(
        children: [
          initPos == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ThemeColors.primaryColor),
                  ),
                )
              : GoogleMap(
                  initialPosition: initPos,
                  initialZoom: ZOOM_VIEW,
                  interactive: true,
                  mapType: map.MapType.terrain,
                  mobilePreferences: MobileMapPreferences(
                      buildingsEnabled: true,
                      trafficEnabled: true,
                      myLocationEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true),
                ),
          if (isArrowClicked)
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedContainer(
                curve: Curves.easeIn,
                duration: Duration(milliseconds: 500),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width <= 600
                    ? MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width / 3 - 130,
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 30.0,
                      spreadRadius: 1)
                ]),
              ),
            ),
          if (deviceView == DeviceView.MOBILE)
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: FloatingActionButton(
                foregroundColor: Colors.white,
                backgroundColor: ThemeColors.primaryColor,
                child: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  if (isArrowClicked) {
                    setState(() {
                      isArrowClicked = false;
                    });
                  } else {
                    setState(() {
                      isArrowClicked = true;
                    });
                  }
                },
              ),
            ),
          if (deviceView == DeviceView.WEB)
            Positioned(
              top: 20.0,
              right: 20.0,
              child: FloatingActionButton(
                foregroundColor: Colors.white,
                backgroundColor: ThemeColors.primaryColor,
                child: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  if (isArrowClicked) {
                    setState(() {
                      isArrowClicked = false;
                    });
                  } else {
                    setState(() {
                      isArrowClicked = true;
                    });
                  }
                },
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 10.0,
                        spreadRadius: 8.0)
                  ]),
              width: MediaQuery.of(context).size.width <= 600
                  ? MediaQuery.of(context).size.width - 40
                  : MediaQuery.of(context).size.width / 3,
              child: TextField(
                onChanged: (val) => searchPlace(val),
                controller: _locationController,
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.my_location),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Your Current Location",
                    border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(10.0))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
