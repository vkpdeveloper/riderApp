import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/controllers/firebase_utils.dart';
import 'package:rideapp/enums/station_view.dart';
import 'package:rideapp/providers/locationViewProvider.dart';
import 'package:rideapp/providers/orderprovider.dart';
import 'package:rideapp/providers/user_provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> capacityFormKey = GlobalKey<FormState>();
  final FirebaseUtils _utils = FirebaseUtils();

  @override
  Widget build(BuildContext context) {
    UserPreferences userPreferences = Provider.of<UserPreferences>(context);
    OrderProvider orderProvider = Provider.of<OrderProvider>(context);
    LocationViewProvider locationViewProvider =
        Provider.of<LocationViewProvider>(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
              color: Colors.white,
            ),
            backgroundColor: ThemeColors.primaryColor,
            title: Text("Order Details")),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              primary: true,
              scrollDirection: Axis.vertical,
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: <Widget>[
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Pickup Point",
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black45))),
                        Row(
                          children: <Widget>[
                            Icon(Icons.location_on,
                                color: ThemeColors.primaryColor),
                            SizedBox(width: 10.0),
                            Flexible(
                              child: Text(
                                locationViewProvider.getPickUpPointAddress,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: ThemeColors.primaryColor,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: <Widget>[
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Destination Point",
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black45))),
                        Stack(
                          overflow: Overflow.visible,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(Icons.location_on,
                                    color: ThemeColors.primaryColor),
                                SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    locationViewProvider
                                        .getDestinationPointAddress,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: ThemeColors.primaryColor,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 15.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text("Receiver Details",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.primaryColor,
                              fontSize: 18.0)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 0.0),
                            child: TextFormField(
                              validator: (val) {
                                if (val.length < 3) {
                                  return "Invalid Name";
                                }
                              },
                              onSaved: (val) {
                                orderProvider.setReceiverName(val);
                              },
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                  hintText: "Receiver Name",
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0))),
                            ),
                          ),
                          SizedBox(height: 15),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 0.0),
                            child: TextFormField(
                              validator: (val) {
                                if (val.length != 10) {
                                  return "Invalid Phone Number";
                                }
                              },
                              onSaved: (val) {
                                orderProvider.setReceiverPhone(val);
                              },
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              decoration: InputDecoration(
                                  hintText: "Receiver Phone",
                                  prefixIcon: Icon(Icons.dialpad),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (orderProvider.getStationView == StationView.LOCAL) ...[
                    SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Select Delivery Mode",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.primaryColor,
                                fontSize: 18.0)),
                      ),
                    ),
                    RadioListTile(
                      onChanged: (val) {
                        orderProvider.setLocalView(val);
                      },
                      activeColor: ThemeColors.primaryColor,
                      groupValue: orderProvider.getSelectedLocalView,
                      title: Text("Part Load"),
                      value: 0,
                    ),
                    RadioListTile(
                      onChanged: (val) {
                        orderProvider.setLocalView(val);
                      },
                      activeColor: ThemeColors.primaryColor,
                      groupValue: orderProvider.getSelectedLocalView,
                      title: Text("Full Truck Load"),
                      value: 1,
                    )
                  ],
                  if (orderProvider.getSelectedLocalView == 0) ...[
                    Form(
                      key: capacityFormKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TextFormField(
                          validator: (val) {
                            if (val.length != 10) {
                              return "Invalid Phone Number";
                            }
                          },
                          onSaved: (val) {
                            orderProvider.setReceiverPhone(val);
                          },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: "In weight",
                              prefixIcon: Icon(Icons.check_box_outline_blank),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0))),
                        ),
                      ),
                    )
                  ],
                  if (orderProvider.getSelectedLocalView == 1 &&
                      orderProvider.getStationView == StationView.LOCAL) ...[
                    SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Select Vehicle",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.primaryColor,
                                fontSize: 18.0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: DropdownButton<String>(
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
                    ),
                    Container(
                      height: 190,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: StreamBuilder(
                            stream: Firestore.instance
                                .collection('trucks')
                                .where("category",
                                    isEqualTo:
                                        orderProvider.getSelectedTruckLocal)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ThemeColors.primaryColor),
                                ));
                              } else {
                                if (snapshot.data.documents.length == 0) {
                                  return Center(
                                      child:
                                          Text("No Trucks of this category !"));
                                }
                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  children: snapshot.data.documents
                                      .map((DocumentSnapshot truck) {
                                    return InkWell(
                                      onTap: () {
                                        orderProvider
                                            .setTruckName(truck.data['name']);
                                      },
                                      child: Container(
                                          height: 180,
                                          width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  3) +
                                              30,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                  color: orderProvider
                                                              .getTruckName ==
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
                                          margin: const EdgeInsets.all(10.0),
                                          child: Container(
                                            child: Column(
                                              children: <Widget>[
                                                SizedBox(height: 5),
                                                ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          truck.data['image'],
                                                      placeholder:
                                                          (context, str) {
                                                        return Container(
                                                          height: 50,
                                                          child: Center(
                                                              child: CircularProgressIndicator(
                                                                  valueColor: AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      ThemeColors
                                                                          .primaryColor))),
                                                        );
                                                      },
                                                    )),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Text(
                                                          truck.data['name'],
                                                          style: TextStyle(
                                                              color: ThemeColors
                                                                  .primaryColor,
                                                              fontSize: 16.0)),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          )),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          )),
                    ),
                  ],
                  if (orderProvider.getStationView == StationView.OUTSIDE) ...[
                    SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Select Vehicle",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.primaryColor,
                                fontSize: 18.0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: DropdownButton<String>(
                          onChanged: (String value) {
                            orderProvider.setTruckCategory(value);
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
                    ),
                    Container(
                      height: 190,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: StreamBuilder(
                            stream: Firestore.instance
                                .collection('trucks')
                                .where("category",
                                    isEqualTo: orderProvider.getSelectedTruck)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ThemeColors.primaryColor),
                                ));
                              } else {
                                if (snapshot.data.documents.length == 0) {
                                  return Center(
                                      child:
                                          Text("No Trucks of this category !"));
                                }
                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  children: snapshot.data.documents
                                      .map((DocumentSnapshot truck) {
                                    return InkWell(
                                      onTap: () {
                                        orderProvider
                                            .setTruckName(truck.data['name']);
                                      },
                                      child: Container(
                                          height: 180,
                                          width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  3) +
                                              30,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                  color: orderProvider
                                                              .getTruckName ==
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
                                          margin: const EdgeInsets.all(10.0),
                                          child: Container(
                                            child: Column(
                                              children: <Widget>[
                                                SizedBox(height: 5),
                                                ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          truck.data['image'],
                                                      placeholder:
                                                          (context, str) {
                                                        return Container(
                                                          height: 50,
                                                          child: Center(
                                                              child: CircularProgressIndicator(
                                                                  valueColor: AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      ThemeColors
                                                                          .primaryColor))),
                                                        );
                                                      },
                                                    )),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Text(
                                                          truck.data['name'],
                                                          style: TextStyle(
                                                              color: ThemeColors
                                                                  .primaryColor,
                                                              fontSize: 16.0)),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          )),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          )),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text("Select Payment Method",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.primaryColor,
                              fontSize: 18.0)),
                    ),
                  ),
                  RadioListTile(
                    activeColor: ThemeColors.primaryColor,
                    onChanged: (val) {
                      orderProvider.setPaymentMethod(val);
                    },
                    value: 0,
                    groupValue: orderProvider.getSelectedPaymentMethod,
                    title: Text("Paytm"),
                  ),
                  RadioListTile(
                    activeColor: ThemeColors.primaryColor,
                    onChanged: (val) {
                      orderProvider.setPaymentMethod(val);
                    },
                    value: 1,
                    groupValue: orderProvider.getSelectedPaymentMethod,
                    title: Text("Credit and Debit Card"),
                  ),
                  SizedBox(height: 60.0),
                ],
              ),
            ),
            Positioned(
              bottom: -5.0,
              right: -4.0,
              left: -4.0,
              child: Card(
                  elevation: 8.0,
                  child: Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                FontAwesome.rupee,
                                color: ThemeColors.primaryColor,
                                size: 25.0,
                              ),
                              SizedBox(width: 5.0),
                              Text(
                                orderProvider.getOrderPrice.toString(),
                                style: GoogleFonts.openSans(
                                    letterSpacing: 1.5,
                                    fontSize: 20.0,
                                    color: ThemeColors.primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        MaterialButton(
                          color: ThemeColors.primaryColor,
                          height: 60.0,
                          minWidth: 180,
                          onPressed: () async {
                            if (formKey.currentState.validate()) {
                              formKey.currentState.save();
                              FocusScope.of(context).unfocus();
                              _utils.startOrder(locationViewProvider,
                                  orderProvider, userPreferences, context);
                            }
                          },
                          child: Text(
                            "Place",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )),
            )
          ],
        ));
  }
}
