import 'package:adminappweb/const/themecolors.dart';
import 'package:adminappweb/controllers/firebase_utils.dart';
import 'package:adminappweb/main.dart';
import 'package:adminappweb/pages/ordermanager.dart';
import 'package:adminappweb/pages/truckmanager.dart';
import 'package:adminappweb/pages/usermanager.dart';
import 'package:adminappweb/pages/vendormanager.dart';
import 'package:adminappweb/widgets/InfoCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  Animation animation;
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    animation = Tween(begin: -1.0, end: 0.0).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    ));
    animationController.forward();
  }

  FirebaseUtils _utils = FirebaseUtils();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0.0,
          backgroundColor: Colors.white,
          title: Text(
            "Dashboard",
            style: TextStyle(color: ThemeColors.primaryColor),
          ),
          actions: [
            IconButton(
                onPressed: () => _utils.sendVerificationEmail(),
                icon: Icon(Icons.notifications),
                color: ThemeColors.primaryColor),
            IconButton(
                onPressed: () {
                  _utils.signOut();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminPanelScreen(),
                      ));
                },
                icon: Icon(Icons.exit_to_app),
                color: ThemeColors.primaryColor),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20.0),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.translationValues(
                          animation.value * width, 0, 0),
                      child: Center(
                        child: Wrap(
                          spacing: 30,
                          runSpacing: 20,
                          direction: Axis.horizontal,
                          children: [
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VendorManager(),
                                  )),
                              icon: Icon(
                                AntDesign.car,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "Vendor Manager",
                              description: "Manage all the vendors from here",
                            ),
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UserManager())),
                              icon: Icon(
                                AntDesign.user,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "User Manager",
                              description: "Manage your users from here",
                            ),
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () {},
                              icon: Icon(
                                AntDesign.message1,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "Support Manager",
                              description: "Support Panel can access from here",
                            ),
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () {},
                              icon: Icon(
                                Entypo.box,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "Unassigned Orders",
                              description:
                                  "Assign and check order details of unassigned orders",
                            ),
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OrderManager())),
                              icon: Icon(
                                FontAwesome5.life_ring,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "Order Manager",
                              description: "Check all the orders from here",
                            ),
                            InfoCard(
                              borderRadius: BorderRadius.circular(10.0),
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width <= 600
                                  ? MediaQuery.of(context).size.width - 30
                                  : MediaQuery.of(context).size.width / 3 - 60,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TruckManager())),
                              icon: Icon(
                                FontAwesome.truck,
                                color: ThemeColors.primaryColor,
                                size: 40.0,
                              ),
                              title: "Truck Manager",
                              description:
                                  "Manage your all the trucks from here",
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ));
  }
}
