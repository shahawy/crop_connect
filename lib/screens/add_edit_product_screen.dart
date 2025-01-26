import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEditProductScreen extends StatefulWidget {
  final String userId;
  final String? productId;

  const AddEditProductScreen({
    Key? key,
    required this.userId,
    this.productId,
  }) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _imageUrl;
  bool _isEditing = false;
  String _userName = '';
  bool _isUserNameLoaded = false;  // New flag to track if the user name has been loaded

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEditing = true;
      _loadProductData();
    }
    _fetchUserName();  // Fetch user's name when the screen is initialized
  }

  // Fetch the user's name based on userId
  Future<void> _fetchUserName() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'Unknown User';
          _isUserNameLoaded = true;  // Set the flag to true when the name is loaded
        });
      } else {
        setState(() {
          _userName = 'Unknown User';
          _isUserNameLoaded = true;  // Set the flag to true even if the user document doesn't exist
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _userName = 'Error fetching user data';
        _isUserNameLoaded = true;  // Set the flag to true in case of an error
      });
    }
  }

  // Load product data if editing an existing product
  Future<void> _loadProductData() async {
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (productDoc.exists) {
      final productData = productDoc.data()!;
      _nameController.text = productData['name'];
      _descriptionController.text = productData['description'];
      _priceController.text = productData['price'].toString();
      _imageUrlController.text = productData['imageUrl'] ?? '';
      _quantityController.text = productData['quantity'].toString();
      setState(() {
        _imageUrl = productData['imageUrl'];
      });
    }
  }

  // Save or update product in Firestore
  Future<void> _saveProduct() async {
    if (_formKey.currentState?.validate() ?? false && _isUserNameLoaded) {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'userId': widget.userId,
        'userName': _userName,  // Include the user's name
        'imageUrl': _imageUrlController.text,  // Store image URL from the new field
        'quantity': int.parse(_quantityController.text),  // Store quantity from the new field
        'dateAdded': FieldValue.serverTimestamp(),  // Add timestamp for when the product is added
      };

      try {
        if (_isEditing) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .update(productData);
          print('Product updated');
        } else {
          await FirebaseFirestore.instance
              .collection('products')
              .add(productData);
          print('Product added');
        }
        Navigator.pop(context);  // Go back to the previous screen
      } catch (e) {
        print('Error saving product: $e');
      }
    } else {
      print('User name is not loaded yet or form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) => value!.isEmpty ? 'Please enter an image URL' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a quantity' : null,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUserNameLoaded ? _saveProduct : null,  // Disable button until the user name is loaded
                child: Text(_isEditing ? 'Update Product' : 'Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF388E3C),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}