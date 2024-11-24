import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'checkout_screen.dart'; // Import CheckoutScreen

class CartScreen extends StatefulWidget {
  final String userId; // Add userId to CartScreen

  CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CollectionReference cartCollection = FirebaseFirestore.instance.collection('cart');

  // Method to calculate total price based on cart items
  double calculateTotalPrice(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Method to update item quantity in Firestore
  void updateItemQuantity(String itemId, int quantity) {
    cartCollection.doc(itemId).update({'quantity': quantity});
  }

  // Method to delete an item from the cart
  void deleteItemFromCart(String itemId) {
    cartCollection.doc(itemId).delete();
  }

  // Navigate to checkout screen
  void proceedToCheckout(List<Map<String, dynamic>> cartItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartItems,
          userId: widget.userId, // Pass userId from CartScreen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cart"),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading cart items"));
          }

          final cartItems = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'],
              'price': data['price'],
              'quantity': data['quantity'],
              'imageUrl': data.containsKey('imageUrl') ? data['imageUrl'] : 'assets/images/placeholder.png',
            };
          }).toList();

          double totalCartPrice = calculateTotalPrice(cartItems);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Image.network(
                          item['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/images/placeholder.png', width: 50, height: 50);
                          },
                        ),
                        title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("\$${item['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                if (item['quantity'] > 1) {
                                  updateItemQuantity(item['id'], item['quantity'] - 1);
                                }
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                updateItemQuantity(item['id'], item['quantity'] + 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                deleteItemFromCart(item['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Total Price: \$${totalCartPrice.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => proceedToCheckout(cartItems),
                  child: Text('Proceed to Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF388E3C),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}