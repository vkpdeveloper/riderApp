import 'package:flutter/material.dart';
import 'package:riderappweb/constants/themecolors.dart';

class DefaultButton extends StatelessWidget {
  final String text;
  final Function press;
  const DefaultButton({
    Key key,
    this.text,
    this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: FlatButton(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        color: ThemeColors.primaryColor,
        onPressed: press,
        textColor: Colors.white,
        child: Text(
          text.toUpperCase(),
        ),
      ),
    );
  }
}