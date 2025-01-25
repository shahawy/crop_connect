import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop_connect/screens/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List cartItems;
  final String userId;

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

  String? _selectedCountryCode = '+1-US';
  String _selectedPaymentMethod = 'Card';

  final List<Map<String, dynamic>> _countryCodes = [
    {'country': 'United States', 'code': '+1-US', 'phoneLength': 10},
    {'country': 'Canada', 'code': '+1-CA', 'phoneLength': 10},
    {'country': 'India', 'code': '+91', 'phoneLength': 10},
    {'country': 'Egypt', 'code': '+20', 'phoneLength': 11},
    // Add more countries and rules as needed
  ];

  double calculateTotalPrice(List cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': widget.userId,
          'user': {
            'name': _fullNameController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'region': _regionController.text,
            'countryCode': _selectedCountryCode,
          },
          'cartItems': widget.cartItems,
          'totalPrice': calculateTotalPrice(widget.cartItems),
          'paymentMethod': _selectedPaymentMethod,
          'orderDate': Timestamp.now(),
          'status': 'Pending',
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              userId: widget.userId,
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

  int getPhoneLength(String? countryCode) {
    final country = _countryCodes.firstWhere((item) => item['code'] == countryCode, orElse: () => {});
    return country['phoneLength'] ?? 10;
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
                    _selectedPaymentMethod = 'Card'; // Reset payment method when changing country
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
                validator: (value) {
                  final phoneLength = getPhoneLength(_selectedCountryCode);
                  return value!.length == phoneLength
                      ? null
                      : 'Phone number must be $phoneLength digits for ${_selectedCountryCode!.split('-')[1]}';
                },
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
              if (_selectedCountryCode == '+20') ...[
                RadioListTile<String>(
                  value: 'COD',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                  title: Text("Cash on Delivery"),
                ),
              ],
              RadioListTile<String>(
                value: 'Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                title: Text("Credit Card"),
                subtitle: _selectedCountryCode != '+20'
                    ? Text("COD is only available in Egypt", style: TextStyle(color: Colors.red))
                    : null,
              ),
              if (_selectedPaymentMethod == 'Card') ...[
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(16), FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value!.length == 16 ? null : 'Card number must be 16 digits',
                  decoration: InputDecoration(labelText: 'Card Number'),
                ),
                SizedBox(height: 10),
    TextFormField(
    controller: _expiryDateController,
    keyboardType: TextInputType.number,
    maxLength: 5, // Limit input to 5 characters (MM/YY)
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter expiry date';
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) {
    return 'Enter expiry date in MM/YY format';
    }
    return null;
    },
    decoration: InputDecoration(
    labelText: 'Expiry Date (MM/YY)',
    hintText: 'MM/YY',
    counterText: '', // Hides the character counter
    ),
    ),

                SizedBox(height: 10),
                TextFormField(
                  controller: _cvcController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [LengthLimitingTextInputFormatter(3), FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => value!.length == 3 ? null : 'CVC must be 3 digits',
                  decoration: InputDecoration(labelText: 'CVC'),
                ),
              ],
              SizedBox(height: 20),
              Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return ListTile(
                    leading: Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(item['name']),
                    subtitle: Text("Quantity: ${item['quantity']} - \$${item['price']}"),
                  );
                },
              ),
              Text(
                "Total: \$${calculateTotalPrice(widget.cartItems).toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              ElevatedButton(
                onPressed: _placeOrder,
                child: Text("Complete Order"),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF388E3C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}