import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart'; // Import CheckoutScreen

class CartScreen extends StatefulWidget {
  final String userId;

  CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CollectionReference cartCollection = FirebaseFirestore.instance.collection('cart');

  // Calculate total price of cart items
  double calculateTotalPrice(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + (item['totalPrice'] ?? 0));
  }

  // Add a product to the cart
  // Add a product to the cart
  void addToCart(String productId, String productName, double price, int quantity) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Error: User is not logged in.");
      return;
    }

    double totalPrice = price * quantity;
    final userId = currentUser.uid;  // Get the userId from FirebaseAuth

    print("Adding product to cart for userId: $userId");

    // Make sure to store the userId as part of the cart item
    cartCollection.add({
      'productId': productId,
      'name': productName,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'userId': userId,  // Store the userId directly from FirebaseAuth
    }).then((value) {
      print("Product added to cart for user: $userId");
    }).catchError((error) {
      print("Failed to add product to cart: $error");
    });
  }

  // Navigate to the checkout screen
  void proceedToCheckout(List<Map<String, dynamic>> cartItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartItems,
          userId: widget.userId,
        ),
      ),
    );
  }

  // Update item quantity
  void updateQuantity(String itemId, int currentQuantity, int change) async {
    try {
      final newQuantity = currentQuantity + change;
      if (newQuantity < 1) return; // Prevent negative quantity

      // Get the document reference
      DocumentSnapshot docSnapshot = await cartCollection.doc(itemId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        double price = data['price'] ?? 0;
        double totalPrice = price * newQuantity;

        // Update the quantity and total price
        await cartCollection.doc(itemId).update({
          'quantity': newQuantity,
          'totalPrice': totalPrice,
        });

        print("Updated item quantity to $newQuantity and total price to $totalPrice.");
      } else {
        print("Item does not exist.");
      }
    } catch (e) {
      print("Failed to update quantity: $e");
    }
  }

  // Delete item from cart
  void removeItemFromCart(String itemId) {
    cartCollection.doc(itemId).delete().catchError((error) {
      print("Failed to delete item: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId.isNotEmpty ? 'Cart ' : 'Crop Connect'),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartCollection.where('userId', isEqualTo: widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading cart items."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Your cart is empty."));
          }

          final cartItems = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'],
              'price': data['price'],
              'quantity': data['quantity'],
              'totalPrice': data['totalPrice'],
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
                                updateQuantity(item['id'], item['quantity'], -1);
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                updateQuantity(item['id'], item['quantity'], 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                removeItemFromCart(item['id']);
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