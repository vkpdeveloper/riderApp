import 'package:rideapp/services/firebase_auth_service.dart';
import 'package:rideapp/services/firebase_storage_service.dart';
import 'package:rideapp/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Used to create user-dependant objects that need to be accessible by all widgets.
/// This widget should live above the [MaterialApp].
/// See [AuthWidget], a descendant widget that consumes the snapshot generated by this builder.
class AuthWidgetBuilder extends StatelessWidget {
  const AuthWidgetBuilder({Key key, @required this.builder}) : super(key: key);
  final Widget Function(BuildContext, AsyncSnapshot<User>) builder;

  @override
  Widget build(BuildContext context) {
    print('AuthWidgetBuilder rebuild');
    final authService =
        Provider.of<FirebaseAuthService>(context, listen: false);
    return StreamBuilder<User>(

      // this stream provides is the user logged in via firebase..we can use this..
      stream: authService.onAuthStateChanged,
      builder: (context, snapshot) {
        print('StreamBuilder: ${snapshot.connectionState}');
        final User user = snapshot.data;
        if (user != null) {
          return MultiProvider(
            providers: [
              Provider<User>.value(value: user),
              Provider<FirestoreService>(
                create: (_) => FirestoreService(uid: user.uid),
              ),
              Provider<FirebaseStorageService>(
                create: (_) => FirebaseStorageService(uid: user.uid),
              ),
            ],
            child: builder(context, snapshot),
          );
        }
        return builder(context, snapshot);
      },
    );
  }
}
