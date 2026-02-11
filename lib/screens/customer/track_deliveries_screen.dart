import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/api.dart';
import 'order_details_screen.dart';

class TrackDeliveriesScreen extends StatefulWidget {
  const TrackDeliveriesScreen({super.key});

  @override
  State<TrackDeliveriesScreen> createState() => _TrackDeliveriesScreenState();
}

class _TrackDeliveriesScreenState extends State<TrackDeliveriesScreen> {
  List<Map<String, dynamic>> activeDeliveries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveDeliveries();
  }

  Future<void> _loadActiveDeliveries() async {
    setState(() => isLoading = true);
    try {
      final orders = await Api.getOrderHistory();
      
      // Filter for pending/assigned orders (active deliveries)
      final active = orders.where((order) {
        final status = (order['status'] ?? '').toString().toLowerCase();
        return status == 'pending' || status == 'assigned';
      }).toList();

      setState(() {
        activeDeliveries = active;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading active deliveries: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading deliveries: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'assigned':
      case 'out_for_delivery':
      case 'out for delivery':
        return Colors.blue;
      case 'in_transit':
      case 'on_the_way':
      case 'on the way':
        return Colors.orange;
      case 'pending':
      case 'preparing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Track Deliveries",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeDeliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 100, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        "No active deliveries",
                        style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your orders will appear here when they're on the way",
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadActiveDeliveries,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActiveDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = activeDeliveries[index];
                      final orderNo = delivery['order_no'] ?? 'N/A';
                      final status = (delivery['status'] ?? 'pending').toString().toLowerCase();

                      return _buildDeliveryCard(
                        context,
                        orderNo: orderNo,
                        orderDate: delivery['order_date'] ?? '',
                        address: delivery['notes'] ?? 'No address provided',
                        status: status,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context, {
    required String orderNo,
    required String orderDate,
    required String address,
    required String status,
  }) {
    int progressStage = _getProgressStage(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderNo: orderNo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$orderNo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Placed on $orderDate",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                "Delivering to:",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              // Progress Timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(icon: Icons.store, label: "Preparing", isActive: progressStage >= 1),
                  _buildStep(icon: Icons.directions_car, label: "On the Way", isActive: progressStage >= 2),
                  _buildStep(icon: Icons.local_shipping, label: "Out for Delivery", isActive: progressStage >= 3),
                  _buildStep(icon: Icons.check_circle, label: "Delivered", isActive: progressStage >= 4),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap for details →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getProgressStage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 1;
      case 'assigned':
        return 2;
      case 'in_transit':
        return 3;
      case 'out_for_delivery':
        return 3;
      case 'completed':
      case 'delivered':
        return 4;
      default:
        return 1;
    }
  }

  Widget _buildStep({required IconData icon, required String label, required bool isActive}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.dark : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}