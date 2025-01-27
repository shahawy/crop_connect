import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String userSearchQuery = '';
  String productSearchQuery = '';

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login'); // Adjust the route name if needed.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign out failed")));
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted")));
    } catch (e) {
      print('Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete user")));
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User role updated")));
    } catch (e) {
      print('Error updating role: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update user role")));
    }
  }

  Stream<QuerySnapshot> _fetchOrders() {
    return FirebaseFirestore.instance.collection('orders').snapshots();
  }

  Stream<QuerySnapshot> _fetchUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot> _fetchProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  Future<Map<String, int>> _getAnalytics() async {
    try {
      int userCount = (await FirebaseFirestore.instance.collection('users').get()).docs.length;
      int productCount = (await FirebaseFirestore.instance.collection('products').get()).docs.length;
      int orderCount = (await FirebaseFirestore.instance.collection('orders').get()).docs.length;
      return {'users': userCount, 'products': productCount, 'orders': orderCount};
    } catch (e) {
      print('Error fetching analytics: $e');
      return {'users': 0, 'products': 0, 'orders': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Color(0xFF388E3C), // A fresh green color
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut(); // Sign out the user
              Navigator.pushReplacementNamed(context, '/'); // Navigate to the login screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analytics Section
              FutureBuilder<Map<String, int>>(
                future: _getAnalytics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  final analytics = snapshot.data!;
                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Total Users: ${analytics['users']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Total Products: ${analytics['products']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Total Orders: ${analytics['orders']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Manage Users Section
              Text('Manage Users:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: StreamBuilder(
                  stream: _fetchUsers(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    var users = snapshot.data!.docs.where((user) => userSearchQuery.isEmpty || (user['name'] ?? '').toLowerCase().contains(userSearchQuery.toLowerCase())).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Search Users', border: OutlineInputBorder()),
                            onChanged: (value) => setState(() => userSearchQuery = value),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var user = users[index];
                            return ListTile(
                              title: Text(user['name']),
                              subtitle: Text(user['email']),
                              trailing: DropdownButton<String>(
                                value: user['role'],
                                items: ['buyer', 'farmer', 'admin'].map((role) {
                                  return DropdownMenuItem(value: role, child: Text(role));
                                }).toList(),
                                onChanged: (newRole) => _updateUserRole(user.id, newRole!),
                              ),
                              onLongPress: () => _deleteUser(user.id),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Manage Products Section
              Text('Manage Products:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: StreamBuilder(
                  stream: _fetchProducts(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    var products = snapshot.data!.docs.where((product) => productSearchQuery.isEmpty || (product['name'] ?? '').toLowerCase().contains(productSearchQuery.toLowerCase())).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Search Products', border: OutlineInputBorder()),
                            onChanged: (value) => setState(() => productSearchQuery = value),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            var product = products[index];
                            var dateAdded = product['dateAdded']?.toDate() ?? DateTime.now();
                            return ListTile(
                              title: Text(product['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price: \$${product['price']}'),
                                  Text('Created At: ${dateAdded.toLocal()}'),
                                ],
                              ),
                              trailing: TextButton(
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () => FirebaseFirestore.instance.collection('products').doc(product.id).delete(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Manage Orders Section
              Text('Manage Orders:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: StreamBuilder(
                  stream: _fetchOrders(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                    var orders = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var order = orders[index];
                        var orderData = order.data() as Map<String, dynamic>;
                        var user = orderData['user'] ?? {};
                        var cartItems = orderData['cartItems'] ?? [];
                        var totalPrice = orderData['totalPrice'] ?? 0;
                        var orderDate = orderData['orderDate']?.toDate() ?? DateTime.now();
                        var status = orderData['status'] ?? 'Pending';
                        var feedback = orderData['feedback'] ?? '';
                        var paymentMethod = orderData['paymentMethod'] ?? '';

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order ID: ${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Order Date: ${orderDate.toLocal()}'),
                                        Text('Phone: ${user['phone']}'),
                                        Text('Name: ${user['name']}'),
                                        Text('Address: ${user['address']}'),
                                        Text('Region: ${user['region']}'),
                                        Text('Total Price: \$${totalPrice}'),
                                        Text('Payment Method: ${paymentMethod}'),
                                        Text('Feedback: ${feedback}'),
                                      ],
                                    ),
                                    // Delete Button
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance.collection('orders').doc(order.id).delete();
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order deleted")));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete order")));
                                        }
                                      },
                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('Products in Cart:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...cartItems.map<Widget>((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text('${item['name']} - \$${item['price']} (x${item['quantity']})'),
                                  );
                                }).toList(),
                                SizedBox(height: 8),
                                DropdownButton<String>(
                                  value: status,
                                  items: ['Pending', 'Confirmed', 'Shipped', 'Delivered'].map((statusOption) {
                                    return DropdownMenuItem(value: statusOption, child: Text(statusOption));
                                  }).toList(),
                                  onChanged: (newStatus) async {
                                    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': newStatus});
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order status updated")));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
