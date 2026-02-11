// import 'package:flutter/material.dart';
// import '../customer/customer_home.dart';   // ← Customer Dashboard
// import '../driver/driver_home.dart';       // ← Driver Dashboard
// import '../../theme/app_colors.dart';

// class RoleSelectScreen extends StatelessWidget {
//   const RoleSelectScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.grey, // Warm cream luxury background
//       appBar: AppBar(
//         title: const Text(
//           "Select Your Role",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: AppColors.gold,
//             letterSpacing: 1.2,
//             fontSize: 22,
//           ),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: AppColors.gold,
//         elevation: 8,
//         shadowColor: AppColors.primaryDark.withOpacity(0.7),
//         centerTitle: true,
//         automaticallyImplyLeading: false, // No back button after login
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Welcome Header
//             Text(
//               "Welcome to DistroHub",
//               style: TextStyle(
//                 fontSize: 34,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.dark,
//                 letterSpacing: 0.5,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               "Choose your role to continue",
//               style: TextStyle(
//                 fontSize: 18,
//                 color: AppColors.dark.withOpacity(0.85),
//                 fontStyle: FontStyle.italic,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 60),

//             // Role Selection Cards
//             Expanded(
//               child: GridView.count(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 28,
//                 crossAxisSpacing: 28,
//                 childAspectRatio: 1.15,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   // CUSTOMER CARD
//                   _buildRoleCard(
//                     context: context,
//                     icon: Icons.shopping_cart_outlined,
//                     title: "Customer",
//                     subtitle: "View orders & track deliveries",
//                     onTap: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (_) => const CustomerHome()), // ← Correct!
//                       );
//                     },
//                   ),

//                   // DRIVER CARD
//                   _buildRoleCard(
//                     context: context,
//                     icon: Icons.local_shipping_outlined,
//                     title: "Driver",
//                     subtitle: "Manage deliveries & routes",
//                     onTap: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (_) => const DriverHome()), // ← Correct!
//                       );
//                     },
//                   ),

//                   // Add more roles later (Distributor, Admin, etc.)
//                 ],
//               ),
//             ),

//             const SizedBox(height: 40),
//             Text(
//               "© 2026 DistroHub. All rights reserved.",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: AppColors.dark.withOpacity(0.6),
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRoleCard({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       borderRadius: BorderRadius.circular(28),
//       elevation: 6,
//       shadowColor: AppColors.goldDark.withOpacity(0.3),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(28),
//         splashColor: AppColors.gold.withOpacity(0.3),
//         highlightColor: AppColors.gold.withOpacity(0.15),
//         child: Container(
//           padding: const EdgeInsets.all(28),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(28),
//             border: Border.all(color: AppColors.goldLight, width: 2.5),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 70,
//                 color: AppColors.gold,
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.dark,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: AppColors.dark.withOpacity(0.85),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }