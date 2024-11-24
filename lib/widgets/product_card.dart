// lib/widgets/product_card.dart
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String productName;

  ProductCard({required this.productName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.fastfood), // Placeholder icon for the product
        title: Text(productName),
        onTap: () {
          // Navigate to product details
          Navigator.pushNamed(context, '/product_details', arguments: productName);
        },
      ),
    );
  }
}