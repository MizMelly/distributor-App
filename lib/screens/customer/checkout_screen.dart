import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/api.dart';
import 'transfer_payment_modal.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'product': product,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: json['product'] as Map<String, dynamic>,
      quantity: json['quantity'] as int,
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ── DATA ────────────────────────────────────────────────
  List<CartItem> cart = [];
  Map<String, dynamic> userProfile = {};
  bool isLoading = true;
  bool isPlacingOrder = false;

  // ── FORM DATA ───────────────────────────────────────────
  String selectedPaymentMethod = 'cash'; // cash, card, transfer
  Map<String, dynamic> transferDetails = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadUserProfile();
  }

  // ── LOAD CART ───────────────────────────────────────────
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

  // ── LOAD USER PROFILE ───────────────────────────────────
  Future<void> _loadUserProfile() async {
    try {
      final profile = await Api.getProfile();
      if (profile != null) {
        setState(() {
          userProfile = profile;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      setState(() => isLoading = false);
    }
  }

  // ── PLACE ORDER ─────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      // Prepare order payload
      final orderItems = cart.map((item) {
        return {
          'product_id': item.product['id'],
          'quantity': item.quantity,
          'unit_price': item.product['unit_price'] ?? item.product['price'] ?? 0,
        };
      }).toList();

      final orderData = {
        'payment_method': selectedPaymentMethod,
        'items': orderItems,
        'total_amount': cartTotal,
        if (selectedPaymentMethod == 'transfer') ...transferDetails,
      };

      // Call API to create order
      final response = await Api.createOrder(orderData);

      if (response['success'] == true) {
        // Clear cart on successful order
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cart');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Order placed successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to products screen
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to place order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
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

  double get deliveryFee => 500;
  double get cartTotal => cartSubtotal + deliveryFee;

  String _formatPrice(double price) {
    return '₦${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _orderSummarySection(),
                  _userDetailsSection(),
                  _paymentSection(),
                  _orderButton(),
                ],
              ),
            ),
    );
  }

  // ── ORDER SUMMARY SECTION ───────────────────────────────
  Widget _orderSummarySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final item = cart[index];
              final price = double.tryParse(
                    (item.product['unit_price'] ?? item.product['price'] ?? 0).toString(),
                  ) ??
                  0;
              final itemTotal = price * item.quantity;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product['name'] ?? 'Unnamed',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(itemTotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: Colors.grey[600])),
              Text(_formatPrice(cartSubtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey[600])),
              Text(_formatPrice(deliveryFee), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Divider(height: 16, color: Colors.grey[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                _formatPrice(cartTotal),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── USER DETAILS SECTION ────────────────────────────────
  Widget _userDetailsSection() {
    final userName = userProfile['name'] ?? 'Guest User';
    final userMobile = userProfile['mobile'] ?? 'Not provided';
    final userAddress = userProfile['address'] ?? 'Not provided';

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery To',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _detailRow(Icons.person_outline, 'Name', userName),
          const SizedBox(height: 12),
          _detailRow(Icons.phone_outlined, 'Mobile', userMobile),
          const SizedBox(height: 12),
          _detailRow(Icons.location_on_outlined, 'Address', userAddress),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── PAYMENT SECTION ─────────────────────────────────────
  Widget _paymentSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _paymentMethodTile(
            'cash',
            'Cash on Delivery',
            'Pay when order arrives',
            Icons.money_outlined,
          ),
          const SizedBox(height: 12),
          _paymentMethodTile(
            'card',
            'Debit/Credit Card',
            'Secure payment with card',
            Icons.credit_card_outlined,
          ),
          const SizedBox(height: 12),
          _paymentMethodTile(
            'transfer',
            'Bank Transfer',
            'Direct transfer to account',
            Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(String value, String title, String subtitle, IconData icon) {
    return GestureDetector(
      onTap: value == 'transfer'
          ? () {
              showDialog(
                context: context,
                builder: (context) => TransferPaymentModal(
                  onSubmit: (details) {
                    setState(() {
                      selectedPaymentMethod = value;
                      transferDetails = details;
                    });
                  },
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedPaymentMethod == value ? AppColors.primary : Colors.grey[300]!,
            width: selectedPaymentMethod == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: RadioListTile<String>(
          value: value,
          groupValue: selectedPaymentMethod,
          onChanged: value == 'transfer'
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    setState(() => selectedPaymentMethod = newValue);
                  }
                },
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          secondary: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  // ── ORDER BUTTON SECTION ────────────────────────────────
  Widget _orderButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: isPlacingOrder ? null : _placeOrder,
          icon: isPlacingOrder ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline),
          label: Text(
            isPlacingOrder ? 'Placing Order...' : 'Place Order',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
