import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

class DeliveryDetails extends StatelessWidget {
  const DeliveryDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer: Olu Beer Shop"),
            const Text("Crates: 40"),
            const Text("Address: Asaba"),

            const Spacer(),

            PrimaryButton(
              text: "Confirm Delivery",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

