import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../core/services/supabase_sync_service.dart'; // ✅ Added for sync logic

// Import Tabs
import 'dashboard/dashboard_tab.dart';
import 'inventory/inventory_tab.dart';
import 'attendance/attendance_tab.dart';
import 'orders/orders_tab.dart'; // ✅ Replaces MenuTab

// Import Widgets
import '../../core/widgets/profile_avatar_button.dart'; // ✅ New Avatar

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// ✅ Logic to pull data manually from the AppBar
  Future<void> _runPullData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pulling latest data from cloud..."),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await SupabaseSyncService.restoreFromCloud();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("✅ Data Synced Successfully"),
             backgroundColor: ThemeConfig.secondaryGreen,
             behavior: SnackBarBehavior.floating,
           )
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red)
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW "OPERATOR" LAYOUT
    final List<Widget> pages = [
      DashboardTab(
        onGoToInventory: () => _onTabTapped(2), // Index 2 is Stock
        onGoToStaff: () => _onTabTapped(3),     // Index 3 is Staff
      ),
      const OrdersTab(),     // Index 1
      const InventoryTab(),  // Index 2
      const AttendanceTab(), // Index 3
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Coffea Manager", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // ✅ NEW: Pull Data Button (Modern Flat Design)
          // Using a subtle tonal style or simple icon to keep it "flat"
          IconButton(
            onPressed: _runPullData,
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: "Pull Data",
            color: ThemeConfig.primaryGreen,
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          const SizedBox(width: 8),

          // ✅ Clean Status Avatar (Handles Menu & Online Indicator)
          const ProfileAvatarButton(),
          
          const SizedBox(width: 16), // Right padding for balance
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThemeConfig.primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined), // ✅ New "Orders" Tab
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Staff',
          ),
        ],
      ),
    );
  }
}