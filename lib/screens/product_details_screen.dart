import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  ProductDetailsScreen({required this.productId});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  double price = 0.0;
  int productQuantity = 0;

  Future<Map<String, dynamic>?> fetchProductDetails() async {
    final docSnapshot = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    return docSnapshot.data();
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> _addToCart(String productId, String name, double price, int quantity) async {
    final cartCollection = FirebaseFirestore.instance.collection('cart');
    await cartCollection.add({
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'totalPrice': price * quantity,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to cart!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Color(0xFF388E3C),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchProductDetails(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading product details'));
          }
          final product = snapshot.data!;
          price = product['price'] ?? 0.0;
          productQuantity = product['quantity'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product['imageUrl'] != null
                      ? Image.network(
                    product['imageUrl'],
                    width: double.infinity,
                    height: 250,  // Reduced image height
                    fit: BoxFit.cover,
                    alignment: Alignment.center,  // Fetch the left half of the image
                  )
                      : Image.asset(
                    'assets/images/placeholder.png',
                    width: double.infinity,
                    height: 250,  // Reduced image height
                    fit: BoxFit.cover,
                    alignment: Alignment.center,  // Fetch the left half of the image
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  product['name'] ?? 'Product Name',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  product['description'] ?? 'No description available.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      onPressed: _decrementQuantity,
                    ),
                    Text(
                      '$quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      color: Colors.green,
                      onPressed: _incrementQuantity,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Total: \$${(price * quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (productQuantity < 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Low Stock! Only $productQuantity left.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _addToCart(widget.productId, product['name'], price, quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF388E3C),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart),
                      SizedBox(width: 10),
                      Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}