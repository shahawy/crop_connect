import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  final Function? refreshCallback;  // Callback to refresh the product list

  const AddEditProductScreen({Key? key, this.productId, this.refreshCallback}) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(); // Controller for quantity
  final TextEditingController _imageUrlController = TextEditingController(); // Controller for quantity

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  // Fetch product data to edit
  Future<void> _loadProductData() async {
    setState(() => _isLoading = true);
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (productDoc.exists) {
      final data = productDoc.data()!;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _quantityController.text = data['quantity']?.toString() ?? ''; // Load quantity
      _imageUrlController.text = data['imageUrl']?.toString() ?? '';
    }
    setState(() => _isLoading = false);
  }

  // Save product data to Firestore
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text) ?? 0, // Save quantity
      'imageUrl': _imageUrlController.text, // Save imageUrl

    };

    try {
      setState(() => _isLoading = true);

      if (widget.productId == null) {
        // Add new product
        await FirebaseFirestore.instance.collection('products').add(productData);
      } else {
        // Update existing product
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
      }

      if (widget.refreshCallback != null) {
        widget.refreshCallback!();  // Call refresh callback to refresh the product list
      }

      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a description' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || double.tryParse(value) == null ? 'Enter a valid price' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || int.tryParse(value) == null || int.tryParse(value) == 0
                    ? 'Enter a valid quantity'
                    : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'ImageUrl'),
                validator: (value) => value == null || value.isEmpty ? 'Enter imageUrl' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF388E3C),
                ),
                child: Text(widget.productId == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}