import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phone_site/provider/test_data.dart';
import 'package:phone_site/screens/inventory/stocks.dart';

class StockSearchPage extends StatefulWidget {
  const StockSearchPage({super.key});

  @override
  State<StockSearchPage> createState() => _StockSearchPageState();
}

class _StockSearchPageState extends State<StockSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    allItems = List<Map<String, dynamic>>.from(testInventoryItems);
  }

  /// 🔎 When user types, filter matching items by name or category
  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = [];
      } else {
        filteredItems = allItems
            .where((item) =>
                item['item_name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                item['item_category']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// ✨ Highlight matching text in orange
  Widget _buildHighlightedText(String text, String query) {
    final matchIndex = text.toLowerCase().indexOf(query.toLowerCase());

    if (matchIndex == -1 || query.isEmpty) {
      return Text(text, style: GoogleFonts.poppins());
    }

    final beforeMatch = text.substring(0, matchIndex);
    final matchText = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 15),
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: matchText,
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔹 Search Bar AppBar
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                height: 42,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          hintText: 'Search for a product...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.black54, size: 20),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                            filteredItems.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      /// 🔹 Search Results or Recent
      body: _controller.text.isEmpty
          ? _buildRecentSearches()
          : _buildSearchResults(),
    );
  }

  /// 🕓 Shows list of recent searches
  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      children: [
        Text(
          'Recent searches',
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...recentSearches.map(
          (term) => ListTile(
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text(term, style: GoogleFonts.poppins()),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  recentSearches.remove(term);
                });
              },
            ),
            onTap: () {
              setState(() {
                _controller.text = term;
                _onSearchChanged(term);
              });
            },
          ),
        ),
      ],
    );
  }

  /// 📋 Displays filtered product suggestions
  Widget _buildSearchResults() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No products found.',
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return ListTile(
          title: _buildHighlightedText(item['item_name'], _controller.text),
          subtitle: Text(
            item['item_category'],
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
          onTap: () {
            // Save to recent
            setState(() {
              recentSearches.remove(item['item_name']);
              recentSearches.insert(0, item['item_name']);
              if (recentSearches.length > 5) {
                recentSearches = recentSearches.sublist(0, 5);
              }
            });

            // Navigate to the StocksPage of the selected category
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StocksPage(
                  category: item['item_category'],
                  highlightItem: item['item_name'],
                   // highlight the item there
                ),
              ),
            );
          },
        );
      },
    );
  }
}
