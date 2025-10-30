import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phone_site/provider/test_data.dart';
import 'widget/add_dialog.dart';
import 'widget/remove_dialog.dart';
import 'widget/sort_button.dart';

class StocksPage extends StatefulWidget {
  final String category;
  final String? highlightItem;

  const StocksPage({super.key, required this.category, this.highlightItem});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  late List<Map<String, dynamic>> filteredStocks;
  static const double lowStockThreshold = 0.3;
  String? currentSort;
  String? highlightedItem;
  final ScrollController _scrollController = ScrollController();
  Map<String, bool> highlightedItems = {};


  @override
  void initState() {
    super.initState();
    _filterAndSort();
    highlightedItem = widget.highlightItem;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.highlightItem != null) {
        _scrollToHighlightedItem(widget.highlightItem!);
        _flashHighlight(widget.highlightItem!);
      }
    });
  }


  void _scrollToHighlightedItem(String itemName) {
    final index =
        filteredStocks.indexWhere((item) => item['item_name'] == itemName);

    if (index != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 120.0, 
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }


  void _filterAndSort() {
    filteredStocks = testInventoryItems
        .where((item) => item['item_category'] == widget.category)
        .map((item) => {...item})
        .toList();

    if (currentSort != null) {
      _applySorting();
    }
  }


  void _applySorting() {
    setState(() {
      if (currentSort == "A - Z") {
        filteredStocks.sort(
          (a, b) =>
              a['item_name'].toString().compareTo(b['item_name'].toString()),
        );
      } 
      else if (currentSort == "Quantity (Low → High)") {
        filteredStocks.sort(
          (a, b) =>
              (a['item_quantity'] ?? 0).compareTo(b['item_quantity'] ?? 0),
        );
      } 
      else if (currentSort == "Quantity (High → Low)") {
        filteredStocks.sort(
          (a, b) =>
              (b['item_quantity'] ?? 0).compareTo(a['item_quantity'] ?? 0),
        ); 
      } 
      else if (currentSort == "Low Stock First") {
        filteredStocks.sort((a, b) {
          double qtyA = (a['item_quantity'] ?? 0).toDouble();
          double qtyB = (b['item_quantity'] ?? 0).toDouble();
          bool aLow = qtyA <= lowStockThreshold;
          bool bLow = qtyB <= lowStockThreshold;
          if (aLow && !bLow) return -1;
          if (!aLow && bLow) return 1;
          return a['item_name'].toString().compareTo(b['item_name'].toString());
        });
      }
    });
  }


  void _flashHighlight(String itemName) async {
    setState(() {
      highlightedItems[itemName] = true;
    });

    await Future.delayed(const Duration(seconds: 1)); // flash for 1 second

    setState(() {
      highlightedItems[itemName] = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(widget.category),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: SortButton(
                onSortSelected: (selected) {
                  setState(() {
                    currentSort = selected;
                    _applySorting();
                  });
                },
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: filteredStocks.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.grey,
                thickness: 0.8,
                height: 20,
                indent: 10,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final stock = filteredStocks[index];
                final isHighlighted = stock['item_name'] == highlightedItem;
                final double qty = (stock['item_quantity'] ?? 0).toDouble();

                Color qtyColor;
                if (qty <= 0.3) {
                  qtyColor = Colors.redAccent;
                } else if (qty <= 0.6) {
                  qtyColor = Colors.orangeAccent;
                } else {
                  qtyColor = Colors.green;
                }
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (highlightedItems[stock['item_name']] == true)
                      ? const Color(0xFFD9D9D9) 
                      : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stock['item_name'],
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (qty <= lowStockThreshold)
                              Image.asset(
                                'assets/notice_icon.png',
                                height: 24,
                                width: 24,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${stock['item_quantity']} ${stock['item_unit']} left',
                          style: GoogleFonts.poppins(
                            color: qtyColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildActionButton(
                              label: 'Remove',
                              color: Colors.redAccent,
                              onPressed: () {
                                RemoveDialog.showRemoveDialog(
                                  context: context,
                                  stock: stock,
                                  onConfirm: () {
                                    print(
                                      "Removed ${stock['item_name']} permanently",
                                    );
                                    // TODO: Replace with DB removal logic
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              label: 'Add Stocks',
                              color: Colors.green,
                              onPressed: () {
                                AddStockDialog.showAddStockDialog(
                                  context: context,
                                  stock: stock,
                                  onConfirm: () {
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
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
  

  Widget _buildHeader(String category) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(133, 101, 54, 1),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 50.0, 20.0, 10.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.navigate_before,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 5),
              Text(
                category,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
