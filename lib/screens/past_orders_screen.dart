import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PastOrdersScreen extends StatefulWidget {
  final String userId;

  PastOrdersScreen({required this.userId});

  @override
  _PastOrdersScreenState createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  late Future<List<Map<String, dynamic>>> pastOrders;

  @override
  void initState() {
    super.initState();
    pastOrders = fetchPastOrders();
  }

  // Fetch orders for the user
  Future<List<Map<String, dynamic>>> fetchPastOrders() async {
    final ordersCollection = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: widget.userId) // Filter by userId
        .orderBy('orderDate', descending: true); // Order by date

    final snapshot = await ordersCollection.get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'orderDate': data['orderDate']?.toDate() ?? DateTime.now(),
        'totalPrice': data['totalPrice'],
        'status': data['status'],
        'cartItems': data['cartItems'] ?? [],
        'feedback': data['feedback'] ?? '', // Include feedback
      };
    }).toList();
  }

  // Function to cancel (delete) an order
  Future<void> cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      // Refresh the data after deleting the order
      setState(() {
        pastOrders = fetchPastOrders(); // Re-fetch orders
      });
    } catch (error) {
      print("Error deleting order: $error");
    }
  }

  // Function to submit feedback
  Future<void> submitFeedback(String orderId, String feedback) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'feedback': feedback, // Save feedback in Firestore
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted successfully!')));
      setState(() {
        pastOrders = fetchPastOrders(); // Re-fetch orders to update feedback
      });
    } catch (error) {
      print("Error submitting feedback: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting feedback.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Orders'),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: pastOrders,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No past orders found.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, index) {
              final order = orders[index];
              final cartItems = order['cartItems'] as List;
              final orderStatus = order['status'];
              final feedbackController = TextEditingController();

              // Pre-fill the feedback if it exists
              if (order['feedback'] != '') {
                feedbackController.text = order['feedback'];
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Order ID: ${order['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Date: ${order['orderDate'].toLocal()}'),
                      Text('Status: ${order['status']}'),
                      Text('Total Price: \$${order['totalPrice']}'),
                      SizedBox(height: 4),
                      Text('Products in Cart:'),
                      ...cartItems.map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('${item['name']} - \$${item['price']} (x${item['quantity']})'),
                        );
                      }).toList(),

                      // Show feedback field if the status is "Delivered"
                      if (orderStatus == 'Delivered') ...[
                        SizedBox(height: 8),
                        Text('Feedback:'),
                        TextField(
                          controller: feedbackController,
                          decoration: InputDecoration(
                            hintText: 'Write your feedback here...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            submitFeedback(order['id'], feedbackController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF388E3C),
                          ),
                          child: Text('Submit Feedback'),
                        ),
                      ],
                    ],
                  ),
                  trailing: orderStatus == 'Pending'
                      ? IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Show confirmation dialog before deleting
                      showDialog(
                        context: ctx,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Cancel Order'),
                            content: Text('Are you sure you want to cancel this order?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  cancelOrder(order['id']); // Cancel the order
                                  Navigator.of(context).pop();
                                },
                                child: Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                      : null, // Don't show the button if status is not 'Pending'
                ),
              );
            },
          );
        },
      ),
    );
  }
}