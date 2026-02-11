import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/api.dart';
import '../auth/login_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'track_deliveries_screen.dart';
import 'order_details_screen.dart';
import 'profile.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    ProductsScreen(),
    OrdersScreen(),
    TrackDeliveriesScreen(),
    ProfileScreen(),
  ];

  // Logout function with confirmation dialog
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears token and user data

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

      return Scaffold(
  backgroundColor: const Color.fromARGB(255, 252, 252, 252),

appBar: isMobile && _currentIndex == 0
    ? AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 85,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Welcome back, Joy 👋",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Here’s what’s happening today",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      )
    : null,

      // BOTTOM NAV – MOBILE ONLY
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: "Place Order"),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "My Order"),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Track"),
                // BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: "Track"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout, color: Color.fromARGB(255, 255, 162, 162)),
                  label: "Logout",
                ),
              ],
              onTap: (index) {
                if (index == 4) {
                  _logout(context);
                } else {
                  setState(() => _currentIndex = index);
                }
              },
            )
          : null,

      // BODY
      body: isMobile
          ? _pages[_currentIndex]
          : Row(
              children: [
                _SideMenu(
                  onSelect: (index) {
                    if (index == 5) {
                      _logout(context);
                    } else {
                      setState(() => _currentIndex = index);
                    }
                  },
                ),
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
    );
  }
}

/* ============================================================
   SIDE MENU (DESKTOP / TABLET)
============================================================ */
class _SideMenu extends StatelessWidget {
  final Function(int) onSelect;

  const _SideMenu({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.account_balance, color: AppColors.gold, size: 36),
              SizedBox(width: 10),
              Text(
                "DistroHub",
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _menuItem(Icons.dashboard, "Dashboard", () => onSelect(0)),
          _menuItem(Icons.shopping_cart, "Place Order", () => onSelect(1)),
          _menuItem(Icons.receipt_long, "My Orders", () => onSelect(2)),
          _menuItem(Icons.local_shipping, "Track Deliveries", () => onSelect(3)),
          _menuItem(Icons.person, "Profile", () => onSelect(4)),
          const Spacer(),
          _menuItem(Icons.logout, "Logout", () => onSelect(5), color: Colors.red),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap,
      {Color color = const Color.fromARGB(255, 246, 245, 245)}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

/* ============================================================
   DASHBOARD HOME – with sliding adverts banner
============================================================ */
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  List<Map<String, dynamic>> recentOrders = [];
  bool isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await Api.getOrderHistory();
      setState(() {
        // Get the last 3 orders
        recentOrders = orders.take(3).toList();
        isLoadingOrders = false;
      });
    } catch (e) {
      print('Error loading recent orders: $e');
      setState(() => isLoadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // You can later fetch these from your backend or store in a provider
    final List<Map<String, String>> adverts = [
  {
    'image': 'assets/images/promo1.jpeg',
    'title': 'Midweek Madness',
  },
  {
    'image': 'assets/images/promo2.jpeg',
    'title': 'Free Delivery Promo',
  },
  {
    'image': 'assets/images/promo3.jpeg',
    'title': 'Bundle Deal',
  },
  {
    'image': 'assets/images/promo4.jpeg',
    'title': 'New Arrivals',
  },
];


    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── ADVERTS BANNER (SLIDING CAROUSEL) ──
          CarouselSlider(
            options: CarouselOptions(
              height: isMobile ? 160 : 200,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.92,
              aspectRatio: 2.3,
              enableInfiniteScroll: true,
              scrollDirection: Axis.horizontal,
            ),
            items: adverts.asMap().entries.map((entry) {
              final advert = entry.value;

              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      // You can navigate to a promo details screen or open URL
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped: ${advert['title']}')),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
  advert['image']!,        // Use local assets
  fit: BoxFit.cover,       // Fills the container without stretching
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: const Color.fromARGB(255, 201, 201, 201),
      child: const Center(
        child: Icon(Icons.local_drink, size: 60, color: Colors.grey),
      ),
    );
  },
),

                            // Semi-transparent overlay + text
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  advert['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // QUICK ACTIONS
          const Text(
            "Quick Actions",
            style: TextStyle(color: Color.fromARGB(255, 206, 46, 46), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: const [
              _QuickAction(icon: Icons.shopping_cart, label: "Place Order"),
              _QuickAction(icon: Icons.receipt_long, label: "My Orders"),
              _QuickAction(icon: Icons.local_shipping, label: "Track Delivery"),
              _QuickAction(icon: Icons.description, label: "Invoices"),
            ],
          ),

          const SizedBox(height: 40),

          // RECENT TRANSACTIONS
          const Text(
            "Recent Transactions",
            style: TextStyle(color: Color.fromARGB(255, 220, 38, 38), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (isLoadingOrders)
            const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recentOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No recent transactions',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...recentOrders.map((order) {
              final orderNo = order['order_no'] ?? 'N/A';
              final totalAmount = order['total_amount'] ?? 0;
              final status = (order['status'] ?? 'unknown').toString();
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(orderNo: orderNo),
                    ),
                  );
                },
                child: _transaction(
                  "Order #$orderNo",
                  _formatPrice(totalAmount),
                  status,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final amount = double.tryParse(price.toString()) ?? 0;
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Widget _transaction(String title, String amount, String status) {
    Color statusColor = status.toLowerCase().contains('pending') 
        ? Colors.orange 
        : status.toLowerCase().contains('completed') 
            ? Colors.green 
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }
}

/* ============================================================
   QUICK ACTION CARD
============================================================ */
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), // 👈 controls height
      decoration: BoxDecoration(
        color: const Color.fromARGB(224, 255, 136, 136),
        borderRadius: BorderRadius.circular(14), // slightly tighter
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26, // 👈 reduced from 36
            color: const Color.fromARGB(255, 214, 43, 43),
          ),
          const SizedBox(height: 6), // 👈 reduced spacing
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12, // 👈 smaller text
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
