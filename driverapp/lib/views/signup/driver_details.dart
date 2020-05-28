import 'package:driverapp/providers/signup_provider.dart';
import 'package:driverapp/views/signup/driver_documents.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/controllers/firebase_utils.dart';
import 'package:provider/provider.dart';

class DriverDetails extends StatefulWidget {
  @override
  _DriverDetailsState createState() => _DriverDetailsState();
}

class _DriverDetailsState extends State<DriverDetails> {
  final _formKey = GlobalKey<FormState>();
  String name, phoneNo, vehiclename, vehicleno, isdriver;
  FirebaseUtils _utils = FirebaseUtils();
  List<String> allTrucks = [];

  @override
  void initState() {
    super.initState();
    getAllTrucks();
  }

  getAllTrucks() async {
    List<String> trucks = await _utils.getAllListOfTrucks();
    if (!mounted) return;
    setState(() {
      allTrucks = trucks;
    });
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want stop signup'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  final BoxDecoration containerdecor = BoxDecoration(
    color: Colors.black12,
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        offset: Offset(2.0, 2.0),
        spreadRadius: 1.0,
        blurRadius: 6.0,
      )
    ],
  );

  @override
  Widget build(BuildContext context) {
    final reference = Firestore.instance.collection("driverSignup");
    SignUpProvider signUpProvider = Provider.of<SignUpProvider>(context);
    return allTrucks == null
        ? Scaffold(
            body: Center(
            child: CircularProgressIndicator(),
          ))
        : WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              backgroundColor: Colors.blue[300],
              body: SafeArea(
                  child: Form(
                autovalidate: true,
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 100,
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 30, 30, 0),
                            child: Text(
                              "Welcome dear partner \nplease provide following Details",
                              style: GoogleFonts.josefinSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0,
                                  color: Colors.black),
                            )),
                      ),
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: TextFormField(
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                labelText: "Name",
                                contentPadding: EdgeInsets.all(4.0),
                                prefixIcon: Icon(Icons.person)),
                            validator: (value) {
                              if (value.length < 4) {
                                return 'Please enter name';
                              }
                              return null;
                            },
                            onSaved: (val) {
                              signUpProvider.setName(val);
                            },
                          )),
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: TextFormField(
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                                labelText: "Mobile Number",
                                contentPadding: EdgeInsets.all(4.0),
                                prefixIcon: Icon(Icons.call)),
                            validator: (value) {
                              if (value.length == 0) {
                                return 'Please enter mobile number';
                              } else if (RegExp(
                                      r"^(\+91[\-\s]?)?[0]?(91)?[789]\d{10}$")
                                  .hasMatch(value)) {
                                return 'Invalid mobile number';
                              }
                              return null;
                            },
                            onSaved: (val) {
                              signUpProvider.setPhone(val);
                            },
                          )),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: DropdownButtonFormField<String>(
                          hint: Text("Vehicle Model"),
                          icon: Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          style: TextStyle(color: Colors.black),
                          onChanged: (String value) {
                            setState(() {
                              vehiclename = value;
                            });
                            signUpProvider.setVehicleName(value);
                          },
                          items: allTrucks
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: TextFormField(
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                labelText: "Vehicle Number",
                                contentPadding: EdgeInsets.all(4.0),
                                prefixIcon: Icon(Icons.directions_bus)),
                            validator: (value) {
                              if (value.length == 0) {
                                return 'Enter Vehicle No';
                              } else if (value.length < 10) {
                                return 'Invalid Vehicle No';
                              }
                              return null;
                            },
                            // ,
                            onSaved: (val) {
                              signUpProvider.setVehicleNumber(val);
                            },
                          )),
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: DropdownButtonFormField<String>(
                            icon: Icon(Icons.arrow_downward),
                            iconSize: 24,
                            elevation: 16,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                labelText: "City",
                                contentPadding: EdgeInsets.all(4.0),
                                prefixIcon: Icon(Icons.location_city)),
                            style: TextStyle(color: Colors.black),
                            onChanged: (value) {
                              setState(() {
                                isdriver = value;
                              });
                              signUpProvider.setCity(value);
                            },
                            items: <String>['Delhi', 'Delhi-NCR', 'Other']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          )),
                      Container(
                        child: MaterialButton(
                          color: Colors.yellow[800],
                          child: Text("Proceed"),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DriverDocuments()),
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )),
            ),
          );
  }
}
