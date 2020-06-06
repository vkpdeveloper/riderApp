import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/constants/apikeys.dart';
import 'package:driverapp/constants/themecolors.dart';
import 'package:driverapp/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/controllers/firebase_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission/permission.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:driverapp/controllers/static_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrder extends StatefulWidget {
  final String orderID;

  const TrackOrder({Key key, this.orderID}) : super(key: key);
  @override
  _TrackOrderState createState() => _TrackOrderState();
}

class _TrackOrderState extends State<TrackOrder> {
  StaticUtils _staticUtils = StaticUtils();
  LatLng _pickUpLatLng;
  LatLng _destinationLatLng;
  String _userName;
  String _receiverName;
  int _price;
  double _distance;
  String _receiverMobileNumber, _userMobileNumber;
  List _addresses;
  CollectionReference _collectionReference =
      Firestore.instance.collection('allOrders');
  GoogleMapController _mapsController;
  Set<Polyline> _polyLines = {};
  Set<Marker> _markers = {};
  GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: APIKeys.googleMapsAPI);
  Map<String, dynamic> dataOfPickUp;
  Map<String, dynamic> dataFromDriver;
  bool isPanelOpen = false;
  List<LatLng> allLats;
  bool _isOrderStarted = false;
  FirebaseUtils _firebaseUtils = FirebaseUtils();
  PanelController _controller;
  String riderAddress;

  @override
  void initState() {
    super.initState();
    getOrderDetails();
    getRiderLocation();
    _controller = PanelController();
  }

  void dispose() {
    super.dispose();
  }

  getOrderDetails() async {
    DocumentSnapshot doc =
        await _collectionReference.document(widget.orderID).get();
    _pickUpLatLng = LatLng(doc.data['pickUpLatLng']['latitude'],
        doc.data['pickUpLatLng']['longitude']);
    _destinationLatLng = LatLng(doc.data['destLatLng']['latitude'],
        doc.data['destLatLng']['longitude']);
    _price = doc.data['price'];
    _distance = doc.data['distance'];
    _userName = doc.data['userName'];
    _receiverName = doc.data['receiverName'];
    _addresses = doc.data['addresses'];
    _isOrderStarted = doc.data['isStart'];
    _receiverMobileNumber = doc.data['receiverPhone'];
    _userMobileNumber = doc.data['userPhone'];
    var permissions =
        await Permission.getPermissionsStatus([PermissionName.Location]);
    if (permissions[0].permissionStatus == PermissionStatus.notAgain) {
      var askpermissions =
          await Permission.requestPermissions([PermissionName.Location]);
    } else {
      try {
        allLats = await _googleMapPolyline.getCoordinatesWithLocation(
            origin: _pickUpLatLng,
            destination: _destinationLatLng,
            mode: RouteMode.driving);
      } catch (e) {
        print(e.toString());
      }
    }
    Map<String, dynamic> mapData =
        await _staticUtils.getDistenceAndDuration(_addresses[0], _addresses[1]);
    setState(() {
      dataOfPickUp = mapData;
    });
  }

  getRiderLocation() async {
    Position position = await Geolocator().getCurrentPosition();
    String address = await _staticUtils
        .getAddressByLatLng(LatLng(position.latitude, position.longitude));
    Map<String, dynamic> mapData =
        await _staticUtils.getDistenceAndDuration(address, _addresses[1]);
    setState(() {
      dataFromDriver = mapData;
      riderAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    OrderProvider provider = Provider.of<OrderProvider>(context);
    return Scaffold(
        body: SlidingUpPanel(
      onPanelSlide: (double offset) {
        if (offset > 0.540) {
          if (!_isOrderStarted) {
            _controller.close();
          } else {
            setState(() {
              isPanelOpen = true;
            });
          }
        } else {
          setState(() {
            isPanelOpen = false;
          });
        }
      },
      defaultPanelState: PanelState.CLOSED,
      body: Stack(
        children: [
          _pickUpLatLng == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ThemeColors.primaryColor),
                  ),
                )
              : GoogleMap(
                  polylines: _polyLines,
                  markers: _markers,
                  onTap: (LatLng newPosition) {},
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  buildingsEnabled: true,
                  scrollGesturesEnabled: true,
                  mapType: MapType.terrain,
                  initialCameraPosition: CameraPosition(
                      target: _pickUpLatLng,
                      zoom: 18.0,
                      tilt: 20.0,
                      bearing: 40.0),
                  onMapCreated: (GoogleMapController controller) {
                    _mapsController = controller;
                    setState(() {
                      _markers.add(Marker(
                          markerId: MarkerId('pickUp'),
                          icon: BitmapDescriptor.defaultMarker,
                          visible: true,
                          draggable: false,
                          position: _pickUpLatLng,
                          infoWindow: InfoWindow(
                              title: "PickUp Position",
                              snippet:
                                  "You have to cover ${dataOfPickUp['distance']}")));
                      _markers.add(Marker(
                          markerId: MarkerId('destination'),
                          icon: BitmapDescriptor.defaultMarker,
                          visible: true,
                          draggable: false,
                          position: _destinationLatLng,
                          infoWindow: InfoWindow(
                              title: "Drop Position",
                              snippet: "This is the drop postion")));
                      _polyLines.add(Polyline(
                          jointType: JointType.round,
                          startCap: Cap.roundCap,
                          endCap: Cap.buttCap,
                          polylineId: PolylineId('location'),
                          color: Colors.lightBlue,
                          width: 8,
                          onTap: () {
                            _mapsController
                                .showMarkerInfoWindow(MarkerId('pickUp'));
                          },
                          geodesic: true,
                          visible: true,
                          points: allLats));
                    });
                  },
                )
        ],
      ),
      controller: _controller,
      header: isPanelOpen
          ? Container()
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    "Hello, Driver",
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width / 2 - 30),
                      child: RichText(
                        text: TextSpan(
                            style: TextStyle(color: ThemeColors.primaryColor),
                            children: [
                              TextSpan(
                                  text: dataOfPickUp == null
                                      ? "loading..."
                                      : dataOfPickUp['duration'])
                            ],
                            text: "Total time : "),
                      ))
                ],
              )),
      minHeight: MediaQuery.of(context).size.height / 3 - 10,
      maxHeight: MediaQuery.of(context).size.height,
      collapsed: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Pickup Address"),
              subtitle: Text(_addresses == null ? "loading..." : _addresses[0]),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Drop Address"),
              subtitle: Text(_addresses == null ? "loading..." : _addresses[1]),
            ),
            if (!_isOrderStarted) ...[
              SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FloatingActionButton.extended(
                      label: Text("Accept"),
                      foregroundColor: Colors.white,
                      backgroundColor: ThemeColors.primaryColor,
                      onPressed: () {
                        _firebaseUtils.acceptOrder(widget.orderID, _controller);
                        setState(() => _isOrderStarted = true);
                      },
                      heroTag: "accept",
                      icon: Icon(Icons.check),
                    ),
                    FloatingActionButton.extended(
                      label: Text("Decline"),
                      foregroundColor: Colors.white,
                      backgroundColor: ThemeColors.primaryColor,
                      onPressed: () =>
                          _firebaseUtils.declineOrder(widget.orderID, context),
                      heroTag: "decline",
                      icon: Icon(Icons.close),
                    )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
      panel: isPanelOpen
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("Pickup Address"),
                    subtitle:
                        Text(_addresses == null ? "loading..." : _addresses[0]),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("Drop Address"),
                    subtitle:
                        Text(_addresses == null ? "loading..." : _addresses[1]),
                  ),
                  ListTile(
                      leading: Icon(Icons.watch_later),
                      title: Text("Duration & Distance (from pickup to drop)"),
                      subtitle: Row(
                        children: <Widget>[
                          Text(dataOfPickUp == null
                              ? "loading..."
                              : dataOfPickUp['duration']),
                          SizedBox(width: 20),
                          Text(dataOfPickUp == null
                              ? "loading..."
                              : dataOfPickUp['distance']),
                        ],
                      )),
                  ListTile(
                      leading: Icon(Icons.watch_later),
                      title: Text(
                          "Duration & Distance (from your location to drop)"),
                      subtitle: Row(
                        children: <Widget>[
                          Text(dataFromDriver == null
                              ? "loading..."
                              : dataFromDriver['duration']),
                          SizedBox(width: 20),
                          Text(dataFromDriver == null
                              ? "loading..."
                              : dataFromDriver['distance']),
                        ],
                      )),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("User Name"),
                    subtitle: Text(_userName),
                  ),
                  ListTile(
                    leading: Icon(Icons.call),
                    trailing: IconButton(
                      onPressed: () => launch("tel: $_userMobileNumber"),
                      color: ThemeColors.primaryColor,
                      icon: Icon(Icons.call),
                    ),
                    title: Text("User Phone"),
                    subtitle: Text(_userMobileNumber.replaceAll("+91", "")),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Receiver Name"),
                    subtitle: Text(_receiverName),
                  ),
                  ListTile(
                    leading: Icon(Icons.call),
                    trailing: IconButton(
                      onPressed: () => launch("tel: +91$_receiverMobileNumber"),
                      color: ThemeColors.primaryColor,
                      icon: Icon(Icons.call),
                    ),
                    title: Text("Receiver Phone"),
                    subtitle: Text(_receiverMobileNumber),
                  ),
                  SizedBox(height: 20),
                  if (provider.getIsPicked)
                    FloatingActionButton.extended(
                      heroTag: "have_delivered",
                      backgroundColor: ThemeColors.primaryColor,
                      foregroundColor: Colors.white,
                      onPressed: () =>
                          _firebaseUtils.pickUpDone(widget.orderID, provider),
                      icon: Icon(Icons.check),
                      label: Text("Delivery Done"),
                    ),
                  if (!provider.getIsPicked)
                    FloatingActionButton.extended(
                      heroTag: "have_picked",
                      backgroundColor: ThemeColors.primaryColor,
                      foregroundColor: Colors.white,
                      onPressed: () =>
                          _firebaseUtils.pickUpDone(widget.orderID, provider),
                      icon: Icon(Icons.check),
                      label: Text("Pickup done"),
                    )
                ],
              ),
            )
          : Container(),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.shade100, blurRadius: 4.0, spreadRadius: 5.0)
      ],
      isDraggable: true,
      parallaxEnabled: true,
      color: Colors.white,
    ));
  }
}
