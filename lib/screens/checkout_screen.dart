import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore
import 'package:crop_connect/screens/order_confirmation_screen.dart';  // Correct the path

class CheckoutScreen extends StatefulWidget {
  final List cartItems;
  final String userId;  // Add the userId here, passed as a parameter

  CheckoutScreen({Key? key, required this.cartItems, required this.userId}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _regionController = TextEditingController();
  TextEditingController _cardNumberController = TextEditingController();
  TextEditingController _expiryDateController = TextEditingController();
  TextEditingController _cvcController = TextEditingController();
  TextEditingController _statusController = TextEditingController();


  String? _selectedCountryCode = '+1-US';  // Default country code with unique identifier
  final List<Map<String, String>> _countryCodes = [
    {'country': 'United States', 'code': '+1-US'},
    {'country': 'Canada', 'code': '+1-CA'},
    {'country': 'India', 'code': '+91'},
    {'country': 'Egypt', 'code': '+20'},
    // Add more countries as needed
  ];

  double calculateTotalPrice(List cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create an order document in Firestore
        final orderRef = await FirebaseFirestore.instance.collection('orders').add({
          'user': {
            'name': _fullNameController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'region': _regionController.text,
            'countryCode': _selectedCountryCode,
          },
          'cartItems': widget.cartItems,
          'totalPrice': calculateTotalPrice(widget.cartItems),
          'orderDate': Timestamp.now(),
          'status': 'Pending'
        });

        // Navigate to the OrderConfirmationScreen with the order ID and userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              userId: widget.userId,  // Pass the userId here
              cartItems: widget.cartItems,
            ),
          ),
        );
      } catch (e) {
        print('Error placing order: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to place order")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Shipping Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCountryCode,
                onChanged: (value) {
                  setState(() {
                    _selectedCountryCode = value!;
                  });
                },
                validator: (value) => value == null ? 'Please select a country code' : null,
                items: _countryCodes
                    .map((item) => DropdownMenuItem<String>(
                  value: item['code'],
                  child: Text('${item['country']} (${item['code']})'),
                ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Select Country Code'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _fullNameController,
                validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _regionController,
                validator: (value) => value!.isEmpty ? 'Please enter your region' : null,
                decoration: InputDecoration(labelText: 'Region'),
              ),
              SizedBox(height: 20),
              Text("Payment Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter your card number' : null,
                decoration: InputDecoration(labelText: 'Card Number'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _expiryDateController,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter expiry date (MM/YY)' : null,
                decoration: InputDecoration(labelText: 'Expiry Date (MM/YY)'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _cvcController,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter CVC' : null,
                decoration: InputDecoration(labelText: 'CVC'),
              ),
              SizedBox(height: 20),
              Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return ListTile(
                    leading: Image.network(
                      item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item['name']),
                    subtitle: Text("Quantity: ${item['quantity']} - \$${item['price']}"),
                  );
                },
              ),
              SizedBox(height: 10),
              Text("Total: \$${calculateTotalPrice(widget.cartItems).toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _placeOrder,  // Call the method to place the order
                child: Text("Complete Order"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF388E3C),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}