import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  // Sample invoices
  static const List<Map<String, dynamic>> invoices = [
    {
      'id': 'INV-2026-001',
      'date': 'Jan 05, 2026',
      'amount': 250000,
      'dueDate': 'Jan 20, 2026',
      'status': 'Paid',
    },
    {
      'id': 'INV-2026-002',
      'date': 'Jan 02, 2026',
      'amount': 450000,
      'dueDate': 'Jan 17, 2026',
      'status': 'Pending',
    },
    {
      'id': 'INV-2025-045',
      'date': 'Dec 28, 2025',
      'amount': 340000,
      'dueDate': 'Jan 05, 2026',
      'status': 'Overdue',
    },
    {
      'id': 'INV-2025-042',
      'date': 'Dec 20, 2025',
      'amount': 180000,
      'dueDate': 'Jan 04, 2026',
      'status': 'Paid',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Overdue':
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
          // ✅ PAGE HEADER (instead of AppBar)
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
              "Invoices",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ✅ PAGE BODY
          Expanded(
            child: invoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          "No invoices yet",
                          style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Your invoices will appear here after placing orders",
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Invoice ${invoice['id']} details coming soon"),
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
                                    Icons.description,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            invoice['id'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(invoice['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              invoice['status'],
                                              style: TextStyle(
                                                color: _getStatusColor(invoice['status']),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text("Issued: ${invoice['date']}", style: TextStyle(color: Colors.grey[600])),
                                      Text(
                                        "Due: ${invoice['dueDate']}",
                                        style: TextStyle(
                                          color: invoice['status'] == 'Overdue'
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "₦${invoice['amount']}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
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
