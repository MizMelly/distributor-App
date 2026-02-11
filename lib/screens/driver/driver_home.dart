import 'package:flutter/material.dart';
import 'delivery_details.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Today's Deliveries",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _DeliveryCard(
            customer: "Olu Beer Shop",
            crates: "40",
            status: "Pending",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DeliveryDetails()),
              );
            },
          ),

          _DeliveryCard(
            customer: "Kings Bar",
            crates: "30",
            status: "Delivered",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String customer;
  final String crates;
  final String status;
  final VoidCallback onTap;

  const _DeliveryCard({
    required this.customer,
    required this.crates,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(customer),
        subtitle: Text("$crates crates • $status"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
