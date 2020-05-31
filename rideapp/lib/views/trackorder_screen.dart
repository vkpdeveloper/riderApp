import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission/permission.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/firebase_utils.dart';
import 'package:rideapp/controllers/static_utils.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderID;
  final Map<String, LatLng> dataMap;
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
  final Set<Polyline> _polyline = {};
  List<LatLng> allLats = [];
  LatLng riderPosition;
  StaticUtils _utils = StaticUtils();
  BitmapDescriptor pinLocationIcon;
  final Set<Marker> _markers = {};
  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: "AIzaSyA7ki0i-XbV6vKgptzZmw7AJhF7wLfpNTc");

  void getPolyLinePoints() async {
    var permissions =
        await Permission.getPermissionsStatus([PermissionName.Location]);
    if (permissions[0].permissionStatus == PermissionStatus.notAgain) {
      var askpermissions =
          await Permission.requestPermissions([PermissionName.Location]);
    } else {
      allLats = await _googleMapPolyline.getCoordinatesWithLocation(
          origin: widget.pickUp,
          destination: widget.destPoint,
          mode: RouteMode.driving);
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
      body: Stack(
        children: <Widget>[
          GoogleMap(
            polylines: _polyline,
            markers: _markers,
            myLocationEnabled: true,
            buildingsEnabled: true,
            scrollGesturesEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            initialCameraPosition: CameraPosition(
                target: widget.pickUp, zoom: 16, bearing: 360.0, tilt: 90.0),
            onMapCreated: (GoogleMapController controller) async {
              Timer.periodic(Duration(minutes: 5), (timer) {
                Firestore.instance
                    .collection('allOrders')
                    .document(widget.orderID)
                    .get()
                    .then((value) {
                  if (mounted) {
                    if (value.data['riderPoint']['latitude'] != riderPosition) {
                      setState(() {
                        riderPosition = LatLng(
                            value.data['riderPoint']['latitude'],
                            value.data['riderPoint']['longitude']);
                        _markers
                            .removeWhere((m) => m.markerId.value == "riderPos");
                        CameraPosition riderCamera = CameraPosition(
                            target: riderPosition,
                            bearing: 360.0,
                            zoom: 16.0,
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
                _polyline.add(Polyline(
                    polylineId: PolylineId('fullLine'),
                    color: ThemeColors.primaryColor,
                    width: 10,
                    startCap: Cap.roundCap,
                    endCap: Cap.buttCap,
                    visible: true,
                    points: allLats));
                _markers.add(Marker(
                    markerId: MarkerId('riderPos'),
                    draggable: false,
                    icon: pinLocationIcon,
                    position: riderPosition,
                    visible: true));
              });
            },
          )
        ],
      ),
    );
  }
}
