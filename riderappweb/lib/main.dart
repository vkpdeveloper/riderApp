import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderappweb/constants/themecolors.dart';

import 'pages/homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Rider App",
      theme: ThemeData(
          textTheme: GoogleFonts.openSansTextTheme(),
          primaryColor: ThemeColors.primaryColor,
          accentColor: Colors.white),
      home: HomePage(),
    );
  }
}
