import 'package:driverapp/providers/auth_provider.dart';
import 'package:driverapp/providers/signup_provider.dart';
import 'package:driverapp/views/profilescreen.dart';
import 'package:driverapp/views/ridesscreen.dart';
import 'package:driverapp/views/signup/Verification.dart';
import 'package:driverapp/views/update_profile.dart';
import 'package:driverapp/views/walletscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:driverapp/constants/themecolors.dart';
import 'package:driverapp/providers/locationViewProvider.dart';
import 'package:driverapp/providers/orderprovider.dart';
import 'package:driverapp/services/firebase_auth_service.dart';
import 'package:driverapp/services/image_picker_service.dart';
import 'package:driverapp/views/homescreen.dart';
import 'package:driverapp/views/loginscreen.dart';
import 'package:driverapp/views/splashscreen.dart';
import 'package:driverapp/views/signup/driver_details.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => LocationViewProvider()),
          ChangeNotifierProvider(
            create: (context) => OrderProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => SignUpProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => AuthProvider(),
          ),
          Provider<FirebaseAuthService>(
            create: (_) => FirebaseAuthService(),
          ),
          Provider<ImagePickerService>(
            create: (_) => ImagePickerService(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Ride App",
          initialRoute: '/',
          routes: {
            '/loginscreen': (context) => LoginScreen(),
            '/homescreen': (context) => VerificationCheck(),
            '/signup': (context) => DriverDetails(),
            '/walletscreen': (context) => WalletScreen(),
            '/ridesscreen': (context) => RidesScreen(),
            '/profilescreen': (context) => Profile(),
            '/updateprofile': (context) => UpdateProfile(),
            '/verification': (cotext)=> Verification(),
          },
          theme: ThemeData(
              textTheme: GoogleFonts.openSansTextTheme(),
              primaryColor: ThemeColors.primaryColor,
              accentColor: Colors.white),
          home: SplashScreen(),
        ));
  }
}
