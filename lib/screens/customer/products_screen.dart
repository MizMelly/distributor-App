import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/api.dart';
import '../../theme/app_colors.dart';
import 'cart_screen.dart';

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

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with WidgetsBindingObserver {
  // ── DATA ────────────────────────────────────────────────
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> displayedProducts = [];
  List<CartItem> cart = [];

  // ── UI STATE ────────────────────────────────────────────
  bool isLoading = true;
  String errorMessage = '';

  // ── PAGINATION & SEARCH ─────────────────────────────────
  int currentPage = 1;
  final int productsPerPage = 8;
  int totalPages = 1;
  String searchQuery = '';
  Timer? _debounce;

  // ── LIFECYCLE ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCart();      // Load saved cart first
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  // Reload cart when screen becomes visible again
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCart();
    }
  }

  // ── LOAD PRODUCTS (once) ────────────────────────────────
  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final res = await Api.fetchProductsPaged(
        page: 1,
        perPage: 1000,
      );

      setState(() {
        allProducts = List<Map<String, dynamic>>.from(res['products'] ?? []);
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.isEmpty) errorMessage = 'Failed to load products';
        isLoading = false;
      });
    }
  }

  // ── FRONTEND FILTER + PAGINATION ────────────────────────
  void _applyFilters() {
    final query = searchQuery.toLowerCase().trim();

    filteredProducts = query.isEmpty
        ? allProducts
        : allProducts.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            return name.contains(query);
          }).toList();

    totalPages = (filteredProducts.length / productsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    if (currentPage > totalPages) currentPage = totalPages;

    _updateDisplayedProducts();
  }

  void _updateDisplayedProducts() {
    final start = (currentPage - 1) * productsPerPage;
    displayedProducts = filteredProducts.skip(start).take(productsPerPage).toList();
    setState(() {});
  }

  // ── SEARCH DEBOUNCE ─────────────────────────────────────
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = value.trim();
        currentPage = 1;
      });
      _applyFilters();
    });
  }

  // ── CART: ADD + SAVE TO JSON ────────────────────────────
  Future<void> _addToCart(Map<String, dynamic> product) async {
    final index = cart.indexWhere((item) => item.product['id'] == product['id']);

    setState(() {
      if (index != -1) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });

    // Save cart to SharedPreferences as JSON
    await _saveCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── SAVE CART TO LOCAL STORAGE (JSON) ───────────────────
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = cart.map((item) => item.toJson()).toList();
    await prefs.setString('cart', jsonEncode(cartJson));
  }

  // ── LOAD CART FROM JSON ON START ────────────────────────
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null && cartString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cartString);
        setState(() {
          cart = decoded.map((json) => CartItem.fromJson(json)).toList();
        });
      } catch (e) {
        debugPrint('Cart load error: $e');
      }
    }
  }

  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Shop Drinks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  ).then((_) {
                    // Refresh cart count when returning from cart screen
                    setState(() {});
                  });
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _content()),
          _paginationControls(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search drinks (Coke, Fanta, Beer...)',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.redAccent, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (displayedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_drink_outlined, size: 90, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No drinks found',
              style: TextStyle(fontSize: 22, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return _productGrid();
  }

  Widget _productGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: displayedProducts.length,
      itemBuilder: (context, index) {
        final product = displayedProducts[index];
        final price = (product['unit_price'] ?? product['price'] ?? 0).toString();
        final isInCart = cart.any((item) => item.product['id'] == product['id']);

        return Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Builder(
                    builder: (context) {
                      final imageUrl = getFirstImageUrl(product['image_urls']);
                      if (imageUrl.isEmpty) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.local_drink, size: 60, color: Colors.grey),
                        );
                      }
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.local_drink, size: 60, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unnamed Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₦${price.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: isInCart ? null : () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.grey[400] : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: isInCart ? 0 : 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isInCart ? 'Added' : 'Add to Cart',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: currentPage > 1 ? AppColors.primary.withOpacity(0.12) : Colors.grey[100],
              foregroundColor: currentPage > 1 ? AppColors.primary : Colors.grey[500],
            ),
            onPressed: currentPage > 1 && !isLoading
                ? () {
                    setState(() => currentPage--);
                    _updateDisplayedProducts();
                  }
                : null,
          ),
          Text(
            '${(currentPage - 1) * productsPerPage + 1}–${(currentPage - 1) * productsPerPage + displayedProducts.length} of ${filteredProducts.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: currentPage < totalPages ? AppColors.primary.withOpacity(0.12) : Colors.grey[100],
              foregroundColor: currentPage < totalPages ? AppColors.primary : Colors.grey[500],
            ),
            onPressed: currentPage < totalPages && !isLoading
                ? () {
                    setState(() => currentPage++);
                    _updateDisplayedProducts();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String getFirstImageUrl(dynamic imageUrls) {
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