import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import 'checkout_screen.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Convert to JSON for saving
  Map<String, dynamic> toJson() => {
        'product': product,
        'quantity': quantity,
      };

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: json['product'] as Map<String, dynamic>,
      quantity: json['quantity'] as int,
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cart = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ── LOAD CART FROM JSON ─────────────────────────────────
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null && cartString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cartString);
        setState(() {
          cart = decoded.map((json) => CartItem.fromJson(json)).toList();
          isLoading = false;
        });
      } catch (e) {
        debugPrint('Cart load error: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // ── SAVE CART TO LOCAL STORAGE (JSON) ───────────────────
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = cart.map((item) => item.toJson()).toList();
    await prefs.setString('cart', jsonEncode(cartJson));
  }

  // ── UPDATE QUANTITY ─────────────────────────────────────
  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    setState(() {
      cart[index].quantity = newQuantity;
    });
    await _saveCart();
  }

  // ── REMOVE ITEM ─────────────────────────────────────────
  Future<void> _removeItem(int index) async {
    final productName = cart[index].product['name'] ?? 'Item';
    
    setState(() {
      cart.removeAt(index);
    });
    
    await _saveCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName removed from cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── CLEAR CART ──────────────────────────────────────────
  Future<void> _clearCart() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => cart.clear());
              _saveCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── CALCULATE TOTALS ────────────────────────────────────
  double get cartSubtotal {
    return cart.fold(0, (sum, item) {
      final price = double.tryParse(
            (item.product['unit_price'] ?? item.product['price'] ?? 0).toString(),
          ) ??
          0;
      return sum + (price * item.quantity);
    });
  }

  double get deliveryFee => 500; // Flat delivery fee
  double get cartTotal => cartSubtotal + deliveryFee;

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.isEmpty
              ? _emptyCart()
              : Column(
                  children: [
                    Expanded(child: _cartList()),
                    _cartSummary(),
                  ],
                ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some drinks to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: cart.length,
      itemBuilder: (context, index) {
        final item = cart[index];
        final product = item.product;
        final price = double.tryParse(
              (product['unit_price'] ?? product['price'] ?? 0).toString(),
            ) ??
            0;
        final itemTotal = price * item.quantity;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _getFirstImageUrl(product['image_urls']),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_drink, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Unnamed',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Quantity Controls
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: OutlinedButton(
                                onPressed: () => _updateQuantity(index, item.quantity - 1),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: const Icon(Icons.remove, size: 14),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: OutlinedButton(
                                onPressed: () => _updateQuantity(index, item.quantity + 1),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: const Icon(Icons.add, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Total & Remove
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${itemTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => _removeItem(index),
                          icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cartSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '₦${cartSubtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Delivery Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '₦${deliveryFee.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Divider(height: 16, color: Colors.grey[300]),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₦${cartTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                );
              },
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Proceed to Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstImageUrl(dynamic imageUrls) {
    if (imageUrls == null) return '';

    try {
      if (imageUrls is List && imageUrls.isNotEmpty) {
        return imageUrls.first.toString();
      }

      if (imageUrls is String && imageUrls.isNotEmpty) {
        final decoded = jsonDecode(imageUrls);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString();
        }
      }
    } catch (e) {
      debugPrint('Image decode error: $e');
    }

    return '';
  }
}
