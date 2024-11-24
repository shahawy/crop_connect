import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/farmer_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_confirmation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDQfCNCOxPugDDPI3jP3QAVB2Fc5Pr8MSE",
        authDomain: "crop-connect-df2f5.firebaseapp.com",
        databaseURL: "https://crop-connect-df2f5-default-rtdb.firebaseio.com",
        projectId: "crop-connect-df2f5",
        storageBucket: "crop-connect-df2f5.firebasestorage.app",
        messagingSenderId: "425607283711",
        appId: "1:425607283711:web:cdd7e7d97f07a439c05dca",
        measurementId: "G-MHB93PXGWW",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(CropConnectApp());
}

class CropConnectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Connect',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthScreen(),
        '/farmer_dashboard': (context) => FarmerDashboardScreen(),
        '/admin_dashboard': (context) => AdminDashboardScreen(),
        '/home': (context) => HomeScreen(),
        '/cart': (context) => CartScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
        '/checkout': (context) => CheckoutScreen(
          cartItems: [], // You can pass actual cart items here
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        '/order_confirmation': (context) {
          String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          List cartItems = []; // Pass actual cart items here

          return OrderConfirmationScreen(
            userId: userId, // Pass the userId to the confirmation screen
            cartItems: cartItems, // Pass cart items
          );
        },
      },
    );
  }
}