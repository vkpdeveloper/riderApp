import 'package:driverapp/views/tripdetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driverapp/constants/themecolors.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                color: ThemeColors.primaryColor,
                height: (MediaQuery.of(context).size.height / 2) - 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text("Daily Earnings",
                            style: GoogleFonts.openSans(
                                letterSpacing: 1.5,
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text("23/05/2020",
                            style: GoogleFonts.openSans(
                                letterSpacing: 1.5,
                                fontSize: 12.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(
                          FontAwesome.arrow_circle_left,
                          color: Colors.white,
                          size: 30.0,
                        ),
                        Row(
                          children: <Widget>[
                            Icon(
                              FontAwesome.rupee,
                              color: Colors.white,
                              size: 30.0,
                            ),
                            SizedBox(width: 5.0),
                            Text(
                              "100.68",
                              style: GoogleFonts.openSans(
                                  letterSpacing: 1.5,
                                  fontSize: 28.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Icon(
                          FontAwesome.arrow_circle_right,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                color: Colors.white24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text("Trip Earning"),
                        Text(
                          "₹ 1200",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text("Incentive"),
                        Text(
                          "₹ 1000",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text("Panelty"),
                        Text(
                          "₹ 100",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text("Surcharge"),
                        Text(
                          "₹ 800",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Divider(
                thickness: 1,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => TripDetails()));
                },
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Card(
                        child: Container(
                          width: _width - 20,
                          child: Column(
                            children: <Widget>[
                              Container(
                                  color: Colors.green,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text("CRN23423424234234 : 4:30 PM"),
                                        Icon(Icons.arrow_forward)
                                      ],
                                    ),
                                  )),
                              Container(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text("Trip Fare"),
                                          Text("₹ 800")
                                        ],
                                      ),
                                      Divider(
                                        color: Colors.black45,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text("Trip Earning"),
                                          Text("₹ 500")
                                        ],
                                      ),
                                      Divider(
                                        color: Colors.black45,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text("Cash Collected"),
                                          Text("₹ 500")
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          Positioned(
            right: 5,
            top: 30,
            child: FlatButton(
                shape: CircleBorder(),
                padding: EdgeInsets.all(8.0),
                onPressed: () {},
                child: Icon(
                  FontAwesome.calendar,
                  color: Colors.white,
                  size: 25,
                )),
          ),
        ],
      ),
    ));
  }
}
