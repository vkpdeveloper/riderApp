import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps/flutter_google_maps.dart';
import 'package:flutter_google_maps/flutter_google_maps.dart' as map;
import 'package:flutter_icons/flutter_icons.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:riderappweb/constants/apikeys.dart';
import 'package:riderappweb/constants/themecolors.dart';
import 'package:riderappweb/enums/devices_view.dart';
import 'package:riderappweb/enums/location_view.dart';
import 'package:riderappweb/enums/station_view.dart';
import 'package:riderappweb/model/location_details.dart';
import 'package:riderappweb/model/location_result.dart';
import 'package:riderappweb/providers/location_provider.dart';
import 'package:riderappweb/providers/order_provider.dart';
import 'package:riderappweb/utils/uuid.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GeoCoord initPos;
  String _pickUpText = "";
  String _dropText = "";
  final double ZOOM_VIEW = 18;
  String currentAddress;
  TextEditingController _locationController = TextEditingController();
  TextEditingController _pickUpController = TextEditingController();
  TextEditingController _dropController = TextEditingController();
  bool isArrowClicked = false;
  DeviceView deviceView;
  Timer _debounce;
  bool hasSearchTerm = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String sessionToken = Uuid().generateV4();
  List<LocationDetails> allLocations = [];
  LocationResult locationResult;
  String searchVal;
  bool isSearchingCurrently = false;
  GlobalKey<FormState> _locationFormKey = GlobalKey<FormState>();
  GlobalKey<GoogleMapStateBase> _googleMapKey = GlobalKey<GoogleMapStateBase>();

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
    _pickUpController.text = currentAddress;
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _pickUpController.addListener(_onSearchPickUp);
    _dropController.addListener(_onSearchDrop);
  }

  _onSearchPickUp() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_pickUpController.text);
    });
  }

  _onSearchDrop() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlace(_dropController.text);
    });
  }

  void searchPlace(String place) {
    setState(() => hasSearchTerm = place.length > 0);
    setState(() {
      searchVal = "Searching...";
    });

    if (place.length < 1) return;

    setState(() {
      isSearchingCurrently = true;
    });

    autoCompleteSearch(place);
  }

  void autoCompleteSearch(String place) async {
    place = place.replaceAll(" ", "+");
    var endpoint = "http://localhost:4000/autocomplete?place=$place";

    // if (locationResult != null) {
    //   endpoint += "&location=${locationResult.latLng.latitude}," +
    //       "${locationResult.latLng.longitude}";
    // }
    get(endpoint, headers: {"Accept": "application/json"}).then((response) {
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var predictions = data['predictions'];
        allLocations.clear();
        if (predictions.isEmpty) {
          setState(() {
            searchVal = "No result found";
            isSearchingCurrently = false;
          });
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
    }).catchError((e) => [print(e)]);
  }

  addDirection(GeoCoord latLng, GeoCoord dest) {
    _googleMapKey.currentState.addDirection(latLng, dest);
  }

  Future<GeoCoord> decodeAndSelectPlace(
      String placeId, LocationViewProvider locationViewProvider) async {
    String endpoint = "http://localhost:4000/decode?placeID=$placeId";

    Response response = await get(endpoint);
    Map<String, dynamic> location =
        jsonDecode(response.body)['result']['geometry']['location'];
    GeoCoord latLng = GeoCoord(location['lat'], location['lng']);
    Map<String, dynamic> northBound = jsonDecode(response.body)['result']
        ['geometry']['viewport']['northeast'];
    Map<String, dynamic> southBound = jsonDecode(response.body)['result']
        ['geometry']['viewport']['southwest'];
    locationViewProvider
        .setNorthestBound(GeoCoord(northBound['lat'], northBound['lng']));
    locationViewProvider
        .setSouthestBound(GeoCoord(southBound['lat'], southBound['lng']));
    return latLng;
  }

  @override
  Widget build(BuildContext context) {
    checkDevice() {
      if (MediaQuery.of(context).size.width <= 700) {
        setState(() {
          if (MediaQuery.of(context).size.height <= 600 == false) {
            if (isArrowClicked)
              isArrowClicked = false;
            else
              isArrowClicked = true;
          } else {
            isArrowClicked = false;
          }
          deviceView = DeviceView.MOBILE;
        });
      } else {
        isArrowClicked = true;
        deviceView = DeviceView.WEB;
      }
    }

    LocationViewProvider locationViewProvider =
        Provider.of<LocationViewProvider>(context);
    OrderProvider orderProvider = Provider.of<OrderProvider>(context);

    checkDevice();

    return Scaffold(
      body: initPos == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(ThemeColors.darkblueColor),
              ),
            )
          : Stack(
              children: [
                Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width),
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width <= 600
                      ? MediaQuery.of(context).size.width
                      : (MediaQuery.of(context).size.width -
                          (MediaQuery.of(context).size.width / 3 - 130)),
                  child: GoogleMap(
                    webPreferences: WebMapPreferences(
                      dragGestures: true,
                      mapTypeControl: true,
                    ),
                    key: _googleMapKey,
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
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 30.0,
                                spreadRadius: 1)
                          ]),
                      child: _buildPanel(locationViewProvider, orderProvider),
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
                if (!isArrowClicked)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 500),
                    top: 60,
                    left: 10,
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
                        readOnly: true,
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

  Widget _buildPanel(
      LocationViewProvider locationViewProvider, OrderProvider orderProvider) {
    return AnimatedPadding(
      duration: Duration(milliseconds: 500),
      padding:
          EdgeInsets.only(top: MediaQuery.of(context).size.height / 6 - 50),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      orderProvider.setStationView(StationView.LOCAL);
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.all(5.0),
                      width: (MediaQuery.of(context).size.width / 9) - 20,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          border:
                              orderProvider.getStationView == StationView.LOCAL
                                  ? Border.all(
                                      color: ThemeColors.primaryColor,
                                      width: 4.0)
                                  : null,
                          color:
                              orderProvider.getStationView == StationView.LOCAL
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
                      orderProvider.setStationView(StationView.OUTSIDESTATION);
                    },
                    child: Container(
                      height: 50,
                      width: (MediaQuery.of(context).size.width / 9) - 20,
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                          border: orderProvider.getStationView ==
                                  StationView.OUTSIDESTATION
                              ? Border.all(
                                  color: ThemeColors.primaryColor, width: 4.0)
                              : null,
                          color: orderProvider.getStationView ==
                                  StationView.OUTSIDESTATION
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    children: <Widget>[
                      Icon(Octicons.primitive_dot,
                          color: ThemeColors.primaryColor),
                      Text(
                          locationViewProvider.getLocationView ==
                                  LocationView.PICKUP
                              ? "Pick Up Location"
                              : "Drop Location",
                          style: TextStyle(
                              fontSize: 16.0,
                              color: ThemeColors.primaryColor,
                              fontWeight: FontWeight.bold))
                    ],
                  )),
            ),
            Form(
              key: _locationFormKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    TextFormField(
                      onTap: () {
                        locationViewProvider
                            .setLocationView(LocationView.PICKUP);
                      },
                      controller: _pickUpController,
                      autofocus: true,
                      onChanged: (val) {
                        setState(() {
                          _pickUpText = val;
                        });
                      },
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 10.0),
                          hintText: "Your Current Location",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0))),
                    ),
                    SizedBox(height: 10.0),
                    TextFormField(
                      onTap: () {
                        locationViewProvider.setLocationView(LocationView.DROP);
                      },
                      onChanged: (val) {
                        setState(() {
                          _dropText = val;
                        });
                      },
                      controller: _dropController,
                      autofocus: true,
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 10.0),
                          hintText: "Enter Drop Location",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0))),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _buildAutoCompleteList(locationViewProvider),
                    _buildOtherItems(locationViewProvider),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildAutoCompleteList(LocationViewProvider locationViewProvider) {
    if (_dropText.isNotEmpty || _pickUpText.isNotEmpty) {
      if (isSearchingCurrently) {
        return ListTile(
          title: Text("Searching..."),
        );
      } else {
        if (searchVal == "No result found") {
          return ListTile(
            title: Text(searchVal),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              LocationDetails detail = allLocations[index];
              return ListTile(
                onTap: () async {
                  GeoCoord geoCoord = await decodeAndSelectPlace(
                      detail.locationID, locationViewProvider);
                  _googleMapKey.currentState.addMarker(Marker(geoCoord));
                  _googleMapKey.currentState.moveCamera(
                      GeoCoordBounds(
                          northeast: locationViewProvider.getNorthestBound,
                          southwest: locationViewProvider.getSouthestBound),
                      animated: true);
                  if (locationViewProvider.getLocationView ==
                      LocationView.PICKUP) {
                    _pickUpController.text = detail.locationAddress;
                    locationViewProvider
                        .setPickUpAddress(detail.locationAddress);
                    locationViewProvider.setPickUpLatLng(geoCoord);
                  } else {
                    _dropController.text = detail.locationAddress;
                    locationViewProvider
                        .setDestinationPointAddress(detail.locationAddress);
                    locationViewProvider.setDestinationLatLng(geoCoord);
                    if (locationViewProvider.getPickUpPointAddress.isNotEmpty) {
                      _googleMapKey.currentState
                          .removeMarker(locationViewProvider.getPickUpLatLng);
                      _googleMapKey.currentState.removeMarker(
                          locationViewProvider.getDestinationLatLng);
                      addDirection(locationViewProvider.getPickUpLatLng,
                          locationViewProvider.getDestinationLatLng);
                      setState(() {
                        isArrowClicked = false;
                      });
                    }
                  }
                },
                title: Text(detail.locationAddress),
              );
            },
            itemCount: allLocations.length,
          );
        }
      }
    } else {
      return Container();
    }
  }

  Widget _buildOtherItems(LocationViewProvider locationViewProvider) {
    if (_dropText.isEmpty || _pickUpText.isEmpty) {
      return Column(
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
            onTap: () {
              locationViewProvider.setPickUpLatLng(initPos);
              locationViewProvider.setAddress(_locationController.text);
              setState(() {
                isArrowClicked = false;
              });
              _googleMapKey.currentState.addMarker(Marker(initPos));
            },
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
      );
    } else {
      return Container();
    }
  }
}
