import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../inventory/inventory_page.dart';
import '../profile/profile_page.dart';
import '../dashboard/widget/time_date.dart';
import '../dashboard/widget/summary_panel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}


class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardContent(), 
    InventoryPage(),
    ProfilePage(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(190, 101, 54, 1), 
        unselectedItemColor: const Color.fromARGB(146, 19, 18, 18),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Logo
              Center(
                child: Image.asset(
                  'assets/logo2.png',
                  height: 100,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 17, 17, 17),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      color: Color.fromRGBO(91, 57, 33, 1),
                      thickness: 1.5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const TimeDateContent(),

              const SizedBox(height: 20),
              const SummaryContent(),
            ],
          ),
        ),
      ),
    );
  }
}