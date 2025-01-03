import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'past_orders_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = '';
  String selectedFilter = 'name';
  int cartItemCount = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchCartItemCount();
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final productCollection = FirebaseFirestore.instance.collection('products');
      final snapshot = await productCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'description': data['description'],
          'price': data['price'],
          'imageUrl': data['imageUrl'] ?? null,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<void> _fetchCartItemCount() async {
    try {
      final userCart = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();
      setState(() {
        cartItemCount = userCart.size;
      });
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    }
  }

  List<Map<String, dynamic>> filterProducts(List<Map<String, dynamic>> products) {
    final filteredProducts = products.where((product) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userId != null ? 'Crop Connect ' : 'Crop Connect'),
        backgroundColor: const Color(0xFF388E3C),
        actions: _auth.currentUser != null ? _buildSignedInActions() : _buildSignedOutActions(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildSortDropdown(),
            const SizedBox(height: 8),
            _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSignedInActions() {
    return [
      IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.shopping_cart),
            if (cartItemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartScreen(userId: userId!)),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.history),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PastOrdersScreen(userId: userId!)),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: () async {
          await _auth.signOut();
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
    ];
  }

  List<Widget> _buildSignedOutActions() {
    return [
      IconButton(
        icon: const Icon(Icons.login),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthScreen()),
          );
        },
      ),
    ];
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search products...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Sort by:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedFilter,
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Name')),
            DropdownMenuItem(value: 'price', child: Text('Price')),
          ],
          onChanged: (value) {
            setState(() {
              selectedFilter = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchProducts(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          final products = filterProducts(snapshot.data!);

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(productId: products[index]['id']),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: products[index]['imageUrl'] != null
                              ? Image.network(
                            products[index]['imageUrl']!,
                            fit: BoxFit.cover,
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${products[index]['price']?.toString() ?? 'N/A'}',
                              style: TextStyle(fontSize: 12, color: Colors.green[700]),
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
    );
  }
}