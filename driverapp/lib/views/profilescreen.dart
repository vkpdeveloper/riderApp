import 'package:driverapp/constants/themecolors.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter_icons/flutter_icons.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.green[200],
      body: SafeArea(
        child: Stack(
          children: <Widget>[
             Positioned(
            right: 1,
            top: 10,
            child: FlatButton(
                shape: CircleBorder(),
                padding: EdgeInsets.all(8.0),
                onPressed: () {},
                child: Icon(
                  FontAwesome.phone,
                  color: Colors.green,
                  size: 25,
                )),
          ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        "Driver Name",
                        style: TextStyle(fontSize: 25),
                      ),
                      Text("Vehicle Name | Vehicle Number")
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                              "https://vaibhavpathakofficial.tk/img/vaibhav.png"),
                          backgroundColor: ThemeColors.primaryColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: SmoothStarRating(
                              allowHalfRating: false,
                              onRated: (v) {},
                              starCount: 5,
                              rating: 3.5,
                              size: 25.0,
                              isReadOnly: true,
                              color: Colors.yellow,
                              borderColor: Colors.yellow,
                              spacing: 0.0),
                        ),
                        Text("3.5"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text("Achievement  "),
                            Icon(FontAwesome.trophy)
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 20,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Done for Today"),
                  ),
                  MaterialButton(
                    minWidth: _width - 40,
                    height: 50,
                    color: Colors.red,
                    onPressed: () {},
                    child: Text(
                      "Go Offline",
                      style: TextStyle(fontSize: 25),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
