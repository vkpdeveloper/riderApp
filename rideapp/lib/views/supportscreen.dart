import 'package:flutter/material.dart';
import 'package:rideapp/views/supportchat.dart';

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Support")),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: Text("Order Support", style: TextStyle(fontSize: 20)),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            leading: Text("Truck Support", style: TextStyle(fontSize: 20)),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => ChatScreen())),
            leading: Text("Chat Support", style: TextStyle(fontSize: 20)),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
