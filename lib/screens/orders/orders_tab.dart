import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/models/transaction_model.dart';
import '../../core/services/hive_service.dart';
import '../../config/theme_config.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  // --- State ---
  String _searchQuery = "";
  DateTime _selectedDate = DateTime.now();
  String _filterStatus = "All"; // "All", "Completed", "Voided"
  String _sortOption = "Newest"; 

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. CONTROL BAR
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search Order # or Cashier...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      ) 
                    : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: _isToday(_selectedDate) ? "Today" : DateFormat('MMM dd').format(_selectedDate),
                      icon: Icons.calendar_today,
                      isActive: !_isToday(_selectedDate),
                      onTap: _pickDate,
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (val) => setState(() => _filterStatus = val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: "All", child: Text("All Status")),
                        const PopupMenuItem(value: "Completed", child: Text("Completed Only")),
                        const PopupMenuItem(value: "Voided", child: Text("Voided Only")),
                      ],
                      child: _buildFilterChip(
                        label: _filterStatus,
                        icon: Icons.filter_list,
                        isActive: _filterStatus != "All",
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (val) => setState(() => _sortOption = val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: "Newest", child: Text("Newest First")),
                        const PopupMenuItem(value: "Oldest", child: Text("Oldest First")),
                        const PopupMenuItem(value: "Amount High", child: Text("Amount (High-Low)")),
                        const PopupMenuItem(value: "Amount Low", child: Text("Amount (Low-High)")),
                      ],
                      child: _buildFilterChip(
                        label: _sortOption,
                        icon: Icons.sort,
                        isActive: _sortOption != "Newest",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. LIST
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: HiveService.transactionBox.listenable(),
            builder: (context, Box<TransactionModel> box, _) {
              // Filter & Sort Logic
              var txns = box.values.where((t) {
                final isSameDay = t.dateTime.year == _selectedDate.year &&
                    t.dateTime.month == _selectedDate.month &&
                    t.dateTime.day == _selectedDate.day;
                if (!isSameDay) return false;

                if (_filterStatus == "Voided" && !t.isVoid) return false;
                if (_filterStatus == "Completed" && t.isVoid) return false;

                if (_searchQuery.isNotEmpty) {
                  final matchRef = (t.referenceNo ?? "").toLowerCase().contains(_searchQuery);
                  final matchCashier = t.cashierName.toLowerCase().contains(_searchQuery);
                  final matchId = t.id.toLowerCase().contains(_searchQuery); 
                  if (!matchRef && !matchCashier && !matchId) return false;
                }
                return true;
              }).toList();

              txns.sort((a, b) {
                switch (_sortOption) {
                  case "Oldest": return a.dateTime.compareTo(b.dateTime);
                  case "Amount High": return b.totalAmount.compareTo(a.totalAmount);
                  case "Amount Low": return a.totalAmount.compareTo(b.totalAmount);
                  case "Newest": 
                  default: return b.dateTime.compareTo(a.dateTime);
                }
              });

              final totalAmount = txns.fold(0.0, (sum, t) => t.isVoid ? sum : sum + t.totalAmount);

              if (txns.isEmpty) return _buildEmptyState();

              return Column(
                children: [
                  // Summary Strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.grey.shade100,
                    child: Text(
                      "${txns.length} Orders • Total: ${NumberFormat.currency(symbol: '₱').format(totalAmount)}",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildStripCard(txns[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- UI HELPERS ---

  Widget _buildStripCard(TransactionModel txn) {
    final dateStr = DateFormat('h:mm a').format(txn.dateTime);
    final statusColor = txn.isVoid ? Colors.red : ThemeConfig.secondaryGreen;
    final statusText = txn.isVoid ? "VOID" : "PAID";

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showTransactionDetails(txn), // OPEN DETAILS
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Colored Strip
              Container(
                width: 6,
                color: statusColor,
              ),

              // 2. Content (Middle) - Takes remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${txn.referenceNo ?? txn.id.substring(0, 6)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$dateStr • ${txn.cashierName}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // Preview items (First 2)
                      ...txn.items.take(2).map((item) => Text(
                        "${item.quantity}x ${item.product.name}",
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                      if (txn.items.length > 2)
                        Text(
                          "+ ${txn.items.length - 2} more items",
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Price & Status (Right) -> FIXED WIDTH CONTAINER
              SizedBox(
                width: 120, // ✅ FIXED WIDTH to prevent layout shifts
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: "₱").format(txn.totalAmount),
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: txn.isVoid ? Colors.grey : ThemeConfig.primaryGreen,
                          decoration: txn.isVoid ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badge Pushed Right
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DETAILS SHEET ---
  void _showTransactionDetails(TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              const SizedBox(height: 12),
              Container(width: 40, height: 4, color: Colors.grey.shade300),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("Order Details", style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: "₱").format(txn.totalAmount),
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold,
                        color: txn.isVoid ? Colors.red : ThemeConfig.primaryGreen,
                        decoration: txn.isVoid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (txn.isVoid)
                      const Text("VOIDED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),

              // List Items
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: txn.items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = txn.items[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            if (item.variant.isNotEmpty)
                              Text(item.variant, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("x${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("₱${item.price.toStringAsFixed(2)}"),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Footer Info
              Container(
                padding: const EdgeInsets.fromLTRB(20,20,20,30),
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    _buildDetailRow("Date", DateFormat('MMM dd, yyyy').format(txn.dateTime)),
                    _buildDetailRow("Time", DateFormat('h:mm a').format(txn.dateTime)),
                    _buildDetailRow("Cashier", txn.cashierName),
                    _buildDetailRow("Payment", txn.paymentMethod),
                    _buildDetailRow("Reference", txn.referenceNo ?? txn.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, color: ThemeConfig.primaryGreen, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeConfig.primaryGreen.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: isActive ? ThemeConfig.primaryGreen : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? ThemeConfig.primaryGreen : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? ThemeConfig.primaryGreen : Colors.grey.shade800),
            ),
            if (onTap == null)
              const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No orders found", style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => setState(() {
              _selectedDate = DateTime.now();
              _filterStatus = "All";
              _searchQuery = "";
              _searchController.clear();
            }),
            child: const Text("Reset Filters"),
          )
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ThemeConfig.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}