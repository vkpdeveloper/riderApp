import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Feature extends StatelessWidget {
  final String feature;

  const Feature({Key key, this.feature}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 140,
      backgroundColor: Theme.of(context).primaryColor,
      child: CircleAvatar(
        radius: 137,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            feature,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold, fontSize: 25.0, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
