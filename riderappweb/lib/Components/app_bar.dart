import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderappweb/pages/termsandconditions.dart';
import 'package:riderappweb/widgets/default_button.dart';

import 'menu_item.dart';

class CustomAppBar extends StatelessWidget {
  final ScrollController scrollController;
  final double height;
  final double width;
  final AnimationController animationController;
  final VoidCallback showLoginDialog;
  final VoidCallback showRegisterDialog;

  const CustomAppBar(
      {Key key,
      this.scrollController,
      this.height,
      this.width,
      this.animationController,
      this.showLoginDialog,
      this.showRegisterDialog})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(46),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 30,
            color: Colors.black.withOpacity(0.16),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 5),
          Text(
            "TRANSPORT DESK",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          if (width <= 880) ...[
            DropdownButton(
              onChanged: (val) {
                print(val);
              },
              icon: Icon(Icons.menu),
              value: "Home",
              items: ['Home', 'Features', 'About', 'Login', 'Get Started']
                  .map((String value) => DropdownMenuItem(
                        child: Text(
                          value,
                          style: GoogleFonts.barlow(),
                        ),
                        value: value,
                      ))
                  .toList(),
            )
          ],
          if (width > 880) ...[
            MenuItem(
              title: "Home",
              press: () {},
            ),
            MenuItem(
                title: "Features",
                press: () {
                  scrollController.animateTo(height + 50,
                      duration: Duration(milliseconds: 100),
                      curve: Curves.linear);
                  animationController.reset();
                  animationController.forward();
                }),
            MenuItem(
              title: "About",
              press: () => scrollController.animateTo(height + 400,
                  duration: Duration(milliseconds: 100), curve: Curves.linear),
            ),
            MenuItem(
                title: "Terms & Conditions",
                press: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TermsAndConditions()))),
            MenuItem(
              title: "Login",
              press: () => showLoginDialog(),
            ),
            DefaultButton(
              text: "Get Started",
              press: () => showRegisterDialog(),
            ),
          ]
        ],
      ),
    );
  }
}
