import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stocks.dart';
import 'widget/search_bar.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

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
              Center(child: Image.asset('assets/logo2.png', height: 100)),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width *
                            0.9, 
                        height: 35,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(217, 217, 217, 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                readOnly: true, 
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StockSearchPage(),
                                    ),
                                  );
                                },
                                decoration: const InputDecoration(
                                  hintText: "Search products...",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Inventory',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 17, 17, 17),
                        ),
                      ),
                    ),

                    const Divider(
                      color: Color.fromRGBO(91, 57, 33, 1),
                      thickness: 1.5,
                    ),

                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 25,
                        mainAxisSpacing: 20,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildCategoryCard(
                            context,
                            'Coffee & Tea Base',
                            'assets/coffee.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Dairy & Creamers',
                            'assets/milk.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Syrups',
                            'assets/syrup.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Sauces & Add-ons',
                            'assets/sauce.png',
                          ),
                          _buildCategoryCard(context, 'Cups', 'assets/cup.png'),
                          _buildCategoryCard(
                            context,
                            'Lids',
                            'assets/lids.png',
                          ),
                          _buildCategoryCard(
                            context,
                            'Straws',
                            'assets/straws.png',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String label,
    String imagePath,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StocksPage(category: label)),
        );
        print("pressed category");
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(153, 245, 245, 245),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(186, 0, 0, 0),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 100),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
