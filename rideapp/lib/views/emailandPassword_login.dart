import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideapp/services/firebase_auth_service.dart';

class EmailLogin extends StatefulWidget {
  @override
  _EmailLoginState createState() => _EmailLoginState();
}

class _EmailLoginState extends State<EmailLogin> {
  String email, password;
  @override
  Widget build(BuildContext context) {
    final _auth = Provider.of<FirebaseAuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.green ,
      body: Container(
        child: SafeArea(
          child: Form(
              child: Column(
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
              ),
              Padding(
                  padding: EdgeInsets.only(left: 25.0, right: 25.0),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.black38,
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
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                          labelText: "Email",
                          contentPadding: EdgeInsets.all(4.0),
                          prefixIcon: Icon(Icons.mail)),
                      onChanged: (val) {
                        setState(() {
                          this.email = val;
                        });
                      },
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              Padding(
                  padding: EdgeInsets.only(left: 25.0, right: 25.0),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.black38,
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
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                          labelText: "Password",
                          contentPadding: EdgeInsets.all(4.0),
                          prefixIcon: Icon(Icons.star)),
                      onChanged: (val) {
                        setState(() {
                          this.password = val;
                        });
                      },
                    ),
                  )),
              SizedBox(height: 10),
              RaisedButton(
                child: Text("Login"),
                onPressed: () {
                  _auth.signInWithEmailAndPassword(email, password);
                },
              )
            ],
          )),
        ),
      ),
    );
  }
}
