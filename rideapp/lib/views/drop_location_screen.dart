import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/providers/locationViewProvider.dart';

class DropLocationMap extends StatelessWidget {
  GoogleMapController _googleMapController;

  @override
  Widget build(BuildContext context) {
    LatLng lastPos;

    LocationViewProvider locationViewProvider =
        Provider.of<LocationViewProvider>(context);
    return Scaffold(
        body: Stack(children: [
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
          onCameraMove: (position) {
            lastPos = position.target;
          },
          onCameraIdle: () async {
            locationViewProvider.setDestinationLatLng(lastPos);
            Coordinates coordinates =
                Coordinates(lastPos.latitude, lastPos.longitude);
            List<Address> allAddress =
                await Geocoder.local.findAddressesFromCoordinates(coordinates);
            String address = allAddress[0].addressLine;
            locationViewProvider.setDestinationPointAddress(address);
          },
          initialCameraPosition: CameraPosition(
              tilt: 60.0,
              bearing: 180,
              zoom: 18,
              target: locationViewProvider.getPickUpLatLng),
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
          mapType: MapType.normal,
        ),
      ),
      Positioned(
        top: 30,
        left: 10.0,
        child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: ThemeColors.primaryColor,
            foregroundColor: Colors.white,
            child: Icon(Icons.arrow_back_ios)),
      ),
      Positioned(
          bottom: 20,
          left: 30.0,
          right: 30.0,
          child: MaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            height: 40.0,
            color: ThemeColors.primaryColor,
            textColor: Colors.white,
            child: Text("Confirm"),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          )),
      pin()
    ]));
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
}
