import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_colors.dart';
import '../../utils/api.dart'; 


class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String searchQuery = '';
  String selectedCategory = 'All';

  // Local cart (can move to Provider/Riverpod later)
  final List<Map<String, dynamic>> _cart = [];

  final List<String> categories = [
    'All',
    'Soft Drinks',
    'Energy Drinks',
    'Water',
    'Juices',
    'Alcoholic',
    'Mixers',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // FIXED: Use the public getToken() method you added
      final token = await Api.getToken();

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _products = data['products'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load drinks';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
      print('Fetch products error: $e');
    }
  }

  List<dynamic> get filteredProducts {
    return _products.where((p) {
      final name = (p['name'] as String?)?.toLowerCase() ?? '';
      final category = (p['category'] as String?) ?? '';
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' || category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  num get cartCount => _cart.fold(0, (sum, item) => sum + (item['quantity'] as num? ?? 0));

  num get cartTotal => _cart.fold(0, (sum, item) {
        final price = item['price'] as num? ?? 0;
        final qty = item['quantity'] as num? ?? 0;
        return sum + (price * qty);
      });

  void _addToCart(dynamic product) {
    final existing = _cart.firstWhere(
      (item) => item['id'] == product['id'],
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      if (existing.isNotEmpty) {
        existing['quantity'] = (existing['quantity'] as num? ?? 0) + 1;
      } else {
        _cart.add({
          ...product,
          'quantity': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Drinks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search drinks (Coke, Pepsi, Fanta...)',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Chips
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, i) {
                            final cat = categories[i];
                            final selected = cat == selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: selected,
                                onSelected: (_) => setState(() => selectedCategory = cat),
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Products Grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 4,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _ProductCard(
                              product: product,
                              onAdd: () => _addToCart(product),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

      // Floating Cart Button
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to Cart screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart: $cartCount items • ₦${cartTotal.toStringAsFixed(0)}'),
                  ),
          
                );
              },
              label: Text('Cart ($cartCount)'),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: AppColors.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Product Card
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] as num?)?.toStringAsFixed(0) ?? '0';
    final stock = product['stock'] as int? ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Builder(
                builder: (context) {
                  final imageUrl = product['image_url'] as String?;
                  if (imageUrl == null || imageUrl.isEmpty) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.local_drink, size: 60, color: Colors.grey),
                    );
                  }
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.local_drink, size: 60, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unnamed Drink',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₦$price',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: $stock units',
                  style: TextStyle(color: stock > 0 ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: stock > 0 ? onAdd : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}