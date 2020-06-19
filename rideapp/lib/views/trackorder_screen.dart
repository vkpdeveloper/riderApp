import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission/permission.dart';
import 'package:rideapp/constants/apikeys.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/static_utils.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderID;

  final Map<String, dynamic> dataMap;
  final LatLng pickUp;
  final LatLng destPoint;

  const TrackOrderScreen(
      {Key key, this.orderID, this.dataMap, this.pickUp, this.destPoint})
      : super(key: key);
  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  GoogleMapController _googleMapController;
  Set<Polyline> _polylines = {};
  List<LatLng> allLats = [LatLng(28.6423, 77.22198000000003), LatLng(28.64324, 77.22181), LatLng(28.64372, 77.22377), LatLng(28.64465, 77.22366999999997), LatLng(28.6449, 77.22201999999999), LatLng(28.6444, 77.21553), LatLng(28.64524, 77.21251999999998), LatLng(28.64631, 77.20547999999997), LatLng(28.64311, 77.20364999999998), LatLng(28.64268, 77.20332000000002), LatLng(28.64449, 77.19929000000002), LatLng(28.64503, 77.19753000000003), LatLng(28.64361, 77.19702000000001), LatLng(28.63496, 77.19065999999998), LatLng(28.63376, 77.18943999999999), LatLng(28.62937, 77.18709999999999), LatLng(28.62461, 77.18216000000001), LatLng(28.62004, 77.17700000000002), LatLng(28.61646, 77.17597999999998), LatLng(28.61222, 77.17489), LatLng(28.60609, 77.17104), LatLng(28.59887, 77.16708), LatLng(28.59584, 77.16633999999999), LatLng(28.59401, 77.16741000000002), LatLng(28.59319, 77.16835000000003), LatLng(28.5924, 77.16784000000001), LatLng(28.59281, 77.16700000000003), LatLng(28.59391, 77.16593999999998), LatLng(28.59078, 77.15841999999998)];
  LatLng riderPosition;
  StaticUtils _utils = StaticUtils();
  BitmapDescriptor pinLocationIcon;
  final Set<Marker> _markers = {};
  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: APIKeys.googleMapsAPI);

  void getPolyLinePoints() async {
    var permissions =
        await Permission.getPermissionsStatus([PermissionName.Location]);
    if (permissions[0].permissionStatus == PermissionStatus.notAgain) {
      var askpermissions =
          await Permission.requestPermissions([PermissionName.Location]);
    } else {
      // allLats = await _googleMapPolyline.getCoordinatesWithLocation(
      //     origin: widget.pickUp,
      //     destination: widget.destPoint,
      //     mode: RouteMode.driving);
      // print(allLats);
    }
  }

  @override
  void initState() {
    super.initState();
    _utils.getBytesFromAsset('asset/images/markerCar.png', 124).then((value) {
      pinLocationIcon = BitmapDescriptor.fromBytes(value);
    });
    getPolyLinePoints();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Track Order"),
      ),
        body: SlidingUpPanel(
      minHeight: MediaQuery.of(context).size.height / 4,
      panel: Container(
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4,
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Driver: ${widget.dataMap['riderName']}",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      "Phone: ${widget.dataMap['riderPhone']}",
                      style: TextStyle(fontSize: 20),
                    ),
                    MaterialButton(
                      color: ThemeColors.primaryColor,
                      textColor: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.phone,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10,),
                          Text("Call Driver")
                        ],
                      ),
                      onPressed: () =>
                          launch("tel:${widget.dataMap['riderPhone']}"),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              top: (MediaQuery.of(context).size.height / 4) / 4,
              right: 10.0,
              child: Container(
                height: 100,
                width: 100,
                child: Image.asset(
                  "asset/images/driverdefault.png",
                  fit: BoxFit.cover,
                ),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            buildingsEnabled: true,
            scrollGesturesEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            initialCameraPosition: CameraPosition(
                target: widget.pickUp, zoom: 2, bearing: 360.0, tilt: 90.0),
            onMapCreated: (GoogleMapController controller) async {
              Timer.periodic(Duration(minutes: 8), (timer) {
                Firestore.instance
                    .collection('allOrders')
                    .document(widget.orderID)
                    .get()
                    .then((value) {
                  if (mounted) {
                    if (value.data['riderPoint'][0] != riderPosition) {
                      setState(() {
                        riderPosition = LatLng(value.data['riderPoint'][0],
                            value.data['riderPoint'][1]);
                        _markers
                            .removeWhere((m) => m.markerId.value == "riderPos");
                        CameraPosition riderCamera = CameraPosition(
                            target: riderPosition,
                            bearing: 360.0,
                            zoom: 6.0,
                            tilt: 90.0);
                        _googleMapController.animateCamera(
                            CameraUpdate.newCameraPosition(riderCamera));
                        _markers.add(Marker(
                            markerId: MarkerId('riderPos'),
                            draggable: false,
                            icon: pinLocationIcon,
                            position: riderPosition,
                            visible: true));
                      });
                    }
                  }
                });
              });
              setState(() {
                _googleMapController = controller;
                riderPosition = widget.pickUp;
                _polylines.add(Polyline(
                    polylineId: PolylineId('564565645'),
                    color: Colors.purple,
                    width: 2,
                    visible: true,
                    points: allLats));
                _markers.add(Marker(
                  markerId: MarkerId("pickup"),
                  visible: true,
                  draggable: false,
                  icon: BitmapDescriptor.defaultMarker,
                  position: widget.pickUp,
                ));
                _markers.add(Marker(
                  markerId: MarkerId("droppos"),
                  visible: true,
                  draggable: false,
                  icon: BitmapDescriptor.defaultMarker,
                  position: widget.destPoint,
                ));
              });
            },
          ),
        ],
      ),
    ));
  }
}
