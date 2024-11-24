import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'past_orders_screen.dart'; // Import the new PastOrdersScreen
import 'auth_screen.dart'; // Assuming AuthScreen is your login/signup page

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = '';
  String selectedFilter = 'name';
  int cartItemCount = 0; // Store the cart item count here
  late String userId;

  // Fetch products from Firestore
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final productCollection = FirebaseFirestore.instance.collection('products');
    final snapshot = await productCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'],
        'description': data['description'],
        'price': data['price'],
        'imageUrl': data.containsKey('imageUrl') ? data['imageUrl'] : null,
      };
    }).toList();
  }

  // Fetch cart item count from Firestore
  Future<int> fetchCartItemCount(String userId) async {
    final userCart = await FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .get();

    return userCart.size; // Return the count of items in the cart
  }

  // Filter products based on the search query and selected filter
  List<Map<String, dynamic>> filterProducts(List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> filteredProducts = products.where((product) {
      return product['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    filteredProducts.sort((a, b) {
      if (selectedFilter == 'price') {
        return (a['price'] as num).compareTo(b['price'] as num);
      } else {
        return (a['name'] as String).compareTo(b['name'] as String);
      }
    });
    return filteredProducts;
  }

  @override
  void initState() {
    super.initState();

    // Get the current user ID
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid; // Store the userId for later use
      fetchCartItemCount(userId).then((count) {
        setState(() {
          cartItemCount = count;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Connect'),
        backgroundColor: Color(0xFF388E3C),
        actions: [
          if (_auth.currentUser != null) ...[
            // Only show these options if the user is signed in
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.shopping_cart),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          cartItemCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                // Pass the userId to the CartScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.history),  // Icon for past orders
              onPressed: () {
                // Navigate to PastOrdersScreen and pass the userId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PastOrdersScreen(userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/'); // Navigate to the landing page after sign-out
              },
            ),
          ] else ...[
            // Show Sign-in button if the user is not signed in
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()), // Navigate to the AuthScreen
                );
              },
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Sort by:'),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Name'),
                    ),
                    DropdownMenuItem(
                      value: 'price',
                      child: Text('Price'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchProducts(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No products available.'));
                  }
                  final products = filterProducts(snapshot.data!);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Display 3 products per row
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,  // Adjust for a smaller layout
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                productId: products[index]['id'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  child: products[index]['imageUrl'] != null
                                      ? Image.network(
                                    products[index]['imageUrl']!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  )
                                      : Image.asset(
                                    'assets/images/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      products[index]['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '\$${products[index]['price']?.toString() ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}