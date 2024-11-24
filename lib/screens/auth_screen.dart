import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController(); // Added name controller
  String _selectedRole = 'buyer'; // Default role is buyer
  bool isLogin = true;

  // Show error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // Sign-up method
  Future<void> signUpWithEmailPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorDialog("Passwords do not match!");
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Add name, email, and role to Firestore after sign-up
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'name': _nameController.text, // Save the name here
        'email': _emailController.text,
        'role': _selectedRole,  // Role saved here (buyer, farmer)
      });

      // Redirect to Sign-In screen after successful sign-up
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      showErrorDialog(e.message ?? "Error signing up");
    }
  }

  // Sign-in method
  Future<void> signInWithEmailPassword() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get user role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        String userRole = userDoc['role'];

        // Navigate to the Home page or respective dashboard based on the role
        if (userRole == 'buyer') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (userRole == 'farmer') {
          Navigator.pushReplacementNamed(context, '/farmer_dashboard');
        } else if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        }
      } else {
        showErrorDialog("User role not found.");
      }
    } on FirebaseAuthException catch (e) {
      showErrorDialog(e.message ?? "Error signing in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Sign In' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLogin) // Only show name field during sign-up
              TextField(
                controller: _nameController, // Added name field
                decoration: InputDecoration(labelText: 'Name'),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            if (!isLogin)
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
              ),
            if (!isLogin)
            // DropdownButton for selecting role (buyer or farmer)
              DropdownButton<String>(
                value: _selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                items: <String>['buyer', 'farmer']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                hint: Text('Select Role'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLogin ? signInWithEmailPassword : signUpWithEmailPassword,
              child: Text(isLogin ? 'Sign In' : 'Sign Up'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin
                  ? 'Don\'t have an account? Sign up'
                  : 'Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}