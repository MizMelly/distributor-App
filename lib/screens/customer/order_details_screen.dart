import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/api.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderNo;

  const OrderDetailsScreen({
    super.key,
    required this.orderNo,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => isLoading = true);
    try {
      final details = await Api.getOrderDetails(widget.orderNo);
      print('Order details response: $details');
      
      if (details != null) {
        setState(() {
          orderDetails = details;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No order details found')),
          );
        }
      }
    } catch (e) {
      print('Error loading order details: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order details: $e')),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPrice(dynamic price) {
    final amount = double.tryParse(price.toString()) ?? 0;
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Order #${widget.orderNo}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load order details',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Order header
                      _buildOrderHeader(),
                      const SizedBox(height: 16),

                      // Order items
                      _buildOrderItems(),
                      const SizedBox(height: 16),

                      // Order summary
                      _buildOrderSummary(),
                      const SizedBox(height: 16),

                      // Payment information
                      _buildPaymentInfo(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderHeader() {
    final order = orderDetails!['order'] as Map<String, dynamic>?;
    if (order == null) {
      return const SizedBox(
        child: Center(
          child: Text('Order information not available'),
        ),
      );
    }

    final status = (order['status'] ?? 'unknown').toString().toUpperCase();
    final orderDate = order['order_date'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(orderDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order['notes'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = (orderDetails!['items'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 16,
              ),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final productName = item['product_name'] ?? 'Product';
                final quantity = item['quantity'] ?? 0;
                final unitPrice = item['unit_price'] ?? 0;
                final totalPrice = item['total_price'] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: $quantity × ${_formatPrice(unitPrice)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(totalPrice),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final order = orderDetails!['order'] as Map<String, dynamic>?;
    if (order == null) {
      return const SizedBox.shrink();
    }

   final totalAmount =
    double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;

final amountPaid =
    double.tryParse(order['amount_paid']?.toString() ?? '0') ?? 0;

final balanceDue =
    double.tryParse(order['balance_due']?.toString() ?? '0') ?? 0;

const double deliveryFee = 500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', totalAmount - deliveryFee),
          const SizedBox(height: 8),
          _summaryRow('Delivery Fee', deliveryFee),
          Divider(color: Colors.grey[300], height: 16),
          _summaryRow(
            'Total Amount',
            totalAmount,
            isTotal: true,
          ),
          const SizedBox(height: 12),
          _summaryRow('Amount Paid', amountPaid, color: Colors.green),
          const SizedBox(height: 8),
          _summaryRow('Balance Due', balanceDue, color: Colors.red),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, dynamic amount,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 13 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.grey[700],
          ),
        ),
        Text(
          _formatPrice(amount),
          style: TextStyle(
            fontSize: isTotal ? 13 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: color ?? (isTotal ? AppColors.primary : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    final payment = orderDetails!['payment'] as Map<String, dynamic>?;
    if (payment == null) {
      return Container(
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
              'Payment Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No payment information available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final paymentMethod = payment['payment_method'] ?? 'N/A';
    final referenceNo = payment['reference_no'] ?? 'N/A';
    final bankName = payment['bank_name'] ?? 'N/A';
    final recipientBankName = payment['recipient_bank_name'] ?? 'N/A';
    final recipientAccountNumber = payment['recipient_account_number'] ?? 'N/A';
    final recipientAccountName = payment['recipient_account_name'] ?? 'N/A';
    final paymentDate = payment['payment_date'] ?? '';
    final paymentProof = payment['payment_proof'];

    return Container(
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
            'Payment Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Payment Method', paymentMethod),
          const SizedBox(height: 8),
          if (paymentMethod.toLowerCase() == 'transfer') ...[
            _infoRow('Your Bank', bankName),
            const SizedBox(height: 8),
            _infoRow('Reference No.', referenceNo),
            const SizedBox(height: 8),
            _infoRow('Recipient Bank', recipientBankName),
            const SizedBox(height: 8),
            _infoRow('Recipient Account', recipientAccountName),
            const SizedBox(height: 8),
            _infoRow('Account Number', recipientAccountNumber),
            const SizedBox(height: 8),
          ],
          if (paymentDate.isNotEmpty) ...[
            _infoRow('Payment Date', _formatDate(paymentDate)),
            const SizedBox(height: 8),
          ],
          // Payment proof images
          if (paymentProof != null && paymentProof is List && paymentProof.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Payment Proof',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: paymentProof.length,
              itemBuilder: (context, index) {
                final imageUrl = paymentProof[index] as String? ?? '';
                return GestureDetector(
                  onTap: imageUrl.isNotEmpty ? () {
                    _showImageViewer(imageUrl);
                  } : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 64,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
