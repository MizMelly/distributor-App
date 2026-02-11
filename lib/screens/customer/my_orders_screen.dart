import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Sample orders data
  static const List<Map<String, dynamic>> orders = [
    {
      'id': 'ORD-142',
      'date': 'Jan 05, 2026',
      'total': 25000,
      'items': 3,
      'status': 'Delivered',
    },
    {
      'id': 'ORD-138',
      'date': 'Jan 02, 2026',
      'total': 50000,
      'items': 5,
      'status': 'In Transit',
    },
    {
      'id': 'ORD-135',
      'date': 'Dec 28, 2025',
      'total': 15000,
      'items': 2,
      'status': 'Pending',
    },
    {
      'id': 'ORD-130',
      'date': 'Dec 20, 2025',
      'total': 30000,
      'items': 4,
      'status': 'Delivered',
    },
    {
      'id': 'ORD-125',
      'date': 'Dec 15, 2025',
      'total': 45000,
      'items': 6,
      'status': 'Cancelled',
    },
  ];

  DateTime? fromDate;
  DateTime? toDate;

  List<Map<String, dynamic>> filteredOrders = [];

  @override
  void initState() {
    super.initState();
    filteredOrders = orders;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
        _filterOrders();
      });
    }
  }

  void _filterOrders() {
    if (fromDate == null || toDate == null) {
      filteredOrders = orders;
      return;
    }

    filteredOrders = orders.where((order) {
      DateTime orderDate = _convertStringToDate(order['date']);
      return orderDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(toDate!.add(const Duration(days: 1)));
    }).toList();
  }

  DateTime _convertStringToDate(String date) {
    return DateFormat("MMM dd, yyyy").parse(date);
  }

  int _calculateTotal() {
    return filteredOrders.fold(
      0,
      (sum, item) => sum + (item['total'] as int),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'In Transit':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Text(
              "My Orders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // FILTER SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pickDate(true),
                        child: Text(
                          fromDate == null
                              ? "From Date"
                              : DateFormat("dd MMM yyyy").format(fromDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _pickDate(false),
                        child: Text(
                          toDate == null
                              ? "To Date"
                              : DateFormat("dd MMM yyyy").format(toDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (fromDate != null && toDate != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Total Report: ₦${_calculateTotal()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ORDER LIST
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(
                    child: Text(
                      "No orders found for selected dates",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsScreen(
                                  orderNo: order['id'],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            order['id'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      order['status'])
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              order['status'],
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                    order['status']),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order['date'],
                                        style: TextStyle(
                                            color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${order['items']} items • ₦${order['total']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
