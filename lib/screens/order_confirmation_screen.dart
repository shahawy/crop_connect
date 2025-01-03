import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class OrderConfirmationScreen extends StatelessWidget {
  final String userId;
  final List cartItems;

  // Constructor
  OrderConfirmationScreen({required this.userId, required this.cartItems});

  // Method to fetch orders for the user from Firestore
  Stream<QuerySnapshot> _fetchUserOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId) // Filter by userId
        .orderBy('orderDate', descending: true) // Optionally order by order date
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Confirmation"),
        backgroundColor: Color(0xFF388E3C), // Green color
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchUserOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders found for this user.'));
          }

          var orders = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
                      var orderDate = order['orderDate'].toDate();
                      var totalPrice = order['totalPrice'];
                      var orderItems = order['cartItems'];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text('Order Date: ${orderDate.toLocal()}'),
                              SizedBox(height: 10),
                              Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
                              SizedBox(height: 10),
                              Text('Items:'),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: orderItems.length,
                                itemBuilder: (context, itemIndex) {
                                  var item = orderItems[itemIndex];
                                  return ListTile(
                                    leading: Image.network(
                                      item['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                    title: Text(item['name']),
                                    subtitle: Text(
                                      'Quantity: ${item['quantity']} - \$${item['price']}',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Return to Home",
                    style: TextStyle(fontSize: 16),
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