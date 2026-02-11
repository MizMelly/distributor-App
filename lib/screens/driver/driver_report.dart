import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';


class DriverReport extends StatelessWidget {
  const DriverReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InputField(label: "Fuel Cost"),
            InputField(label: "Other Expenses"),
            PrimaryButton(text: "Submit Report", onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
