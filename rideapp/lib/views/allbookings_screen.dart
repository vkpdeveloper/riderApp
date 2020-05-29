import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/constants/themecolors.dart';
import 'package:rideapp/providers/user_provider.dart';

class AllBookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    UserPreferences userPreferences = Provider.of<UserPreferences>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text("Order History"),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('allOrders')
            .where("userID", isEqualTo: userPreferences.getUserID)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print("error in snapshot ${snapshot.error}");
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColors.primaryColor)));
            default:
              if (snapshot.data.documents.length == 0)
                return Center(child: Text("No Previous Orders"));
              else {
                return ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        child: Card(
                          elevation: 8.0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0)),
                          child: Container(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "Order ID : ${document["orderID"]}",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10.0,
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "Your Agent : ${document["riderPhone"]}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10.0,
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      "Payment Type : ${document["paymentMethod"]}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8.0,
                                  ),
                                  getDropDetails(document, context)
                                ],
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
          }
        },
      ),
    );
  }

  Widget getDropDetails(DocumentSnapshot document, BuildContext context) {
    if (document.data['isStart'] && !document.data['isDelivered']) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MaterialButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0)),
            onPressed: () {},
            color: ThemeColors.primaryColor,
            child: Text(
              "TRACK ORDER",
              style: TextStyle(color: Colors.white),
            ),
            minWidth: (MediaQuery.of(context).size.width - 70),
          )
        ],
      );
    } else if (!document.data['isStart']) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "ORDER NOT STARTED YET !",
            style: TextStyle(
                color: ThemeColors.primaryColor,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
          )
        ],
      );
    } else if (document.data['isStart'] && document.data['isDelivered']) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "ORDER DELIVERED SUCCESSFULLY",
            style: TextStyle(
                color: ThemeColors.primaryColor,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
          )
        ],
      );
    }
  }
}
