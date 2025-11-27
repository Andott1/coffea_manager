import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/models/ingredient_model.dart';
import '../../core/models/inventory_log_model.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/inventory_log_service.dart';
import '../../core/services/supabase_sync_service.dart'; // ✅ Added Import
import '../../config/theme_config.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // --- State ---
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _sortOption = "Name (A-Z)";
  DateTimeRange? _selectedDateRange;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Default to last 7 days for history logs
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)), 
      end: now
    );

    // Context-aware resets when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _sortOption = "Name (A-Z)";
          } else {
            _sortOption = "Newest First";
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. TABS
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: ThemeConfig.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ThemeConfig.primaryGreen,
            tabs: const [
              Tab(text: "Stock Levels"),
              Tab(text: "History Logs"),
            ],
          ),
        ),

        // 2. CONTROL BAR (Search + Filters)
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
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search ingredients...",
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

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // DATE RANGE (History Only)
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildFilterChip(
                              label: _selectedDateRange == null 
                                ? "All Time"
                                : "${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}",
                              icon: Icons.date_range,
                              isActive: true,
                              onTap: _pickDateRange,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Category Filter
                    ValueListenableBuilder(
                      valueListenable: HiveService.ingredientBox.listenable(),
                      builder: (context, Box<IngredientModel> box, _) {
                        final categories = ["All", ...box.values.map((e) => e.category).toSet().toList()..sort()];
                        return PopupMenuButton<String>(
                          onSelected: (val) => setState(() => _selectedCategory = val),
                          itemBuilder: (context) => categories.map((c) => 
                            PopupMenuItem(value: c, child: Text(c))
                          ).toList(),
                          child: _buildFilterChip(
                            label: _selectedCategory,
                            icon: Icons.category,
                            isActive: _selectedCategory != "All",
                          ),
                        );
                      }
                    ),

                    const SizedBox(width: 8),

                    // Sort Filter
                    PopupMenuButton<String>(
                      onSelected: (val) => setState(() => _sortOption = val),
                      itemBuilder: (context) {
                        if (_tabController.index == 0) {
                          return [
                            const PopupMenuItem(value: "Name (A-Z)", child: Text("Name (A-Z)")),
                            const PopupMenuItem(value: "Name (Z-A)", child: Text("Name (Z-A)")),
                            const PopupMenuItem(value: "Low Stock", child: Text("Low Stock First")),
                            const PopupMenuItem(value: "High Stock", child: Text("High Stock First")),
                          ];
                        } else {
                          return [
                            const PopupMenuItem(value: "Newest First", child: Text("Newest First")),
                            const PopupMenuItem(value: "Oldest First", child: Text("Oldest First")),
                          ];
                        }
                      },
                      child: _buildFilterChip(
                        label: _sortOption,
                        icon: Icons.sort,
                        isActive: _sortOption != "Name (A-Z)" && _sortOption != "Newest First",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. TAB CONTENT (Gray Background)
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStockList(),
                _buildHistoryList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 📦 TAB 1: STOCK LEVELS
  // ---------------------------------------------------------------------------
  Widget _buildStockList() {
    return ValueListenableBuilder(
      valueListenable: HiveService.ingredientBox.listenable(),
      builder: (context, Box<IngredientModel> box, _) {
        var ingredients = box.values.where((ing) {
          final matchesSearch = ing.name.toLowerCase().contains(_searchQuery);
          final matchesCategory = _selectedCategory == "All" || ing.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        // Sort Logic
        ingredients.sort((a, b) {
          switch (_sortOption) {
            case "Name (Z-A)": return b.name.compareTo(a.name);
            case "Low Stock": return a.quantity.compareTo(b.quantity);
            case "High Stock": return b.quantity.compareTo(a.quantity);
            case "Name (A-Z)": 
            default: return a.name.compareTo(b.name);
          }
        });

        if (ingredients.isEmpty) return _buildEmptyState("No ingredients found");

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ingredients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ing = ingredients[index];
            final isLowStock = ing.quantity <= ing.reorderLevel;

            // White Card Style
            return Material(
              color: Colors.white,
              elevation: 1,
              shadowColor: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red.shade50 : ThemeConfig.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.kitchen, 
                        color: isLowStock ? Colors.red : ThemeConfig.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          // Uses displayString (e.g. "0.8 L" instead of "800 L")
                          Text(
                            "${ing.displayString} available", 
                            style: TextStyle(
                              color: isLowStock ? Colors.red : Colors.grey.shade700,
                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action
                    ElevatedButton(
                      onPressed: () => _showAdjustmentSheet(context, ing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLowStock ? Colors.red : ThemeConfig.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text("Adjust", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 📜 TAB 2: HISTORY LOGS
  // ---------------------------------------------------------------------------
  Widget _buildHistoryList() {
    return ValueListenableBuilder(
      valueListenable: HiveService.logsBox.listenable(),
      builder: (context, Box<InventoryLogModel> box, _) {
        final allLogs = box.values.toList();

        final filteredLogs = allLogs.where((log) {
          // 1. Date Range
          if (_selectedDateRange != null) {
            final logDate = log.dateTime;
            final start = _selectedDateRange!.start;
            final end = _selectedDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
            if (logDate.isBefore(start) || logDate.isAfter(end)) return false;
          }

          // 2. Search Text
          final matchesSearch = log.ingredientName.toLowerCase().contains(_searchQuery) ||
                                log.userName.toLowerCase().contains(_searchQuery);
          if (!matchesSearch) return false;

          // 3. Category Filter
          if (_selectedCategory != "All") {
            try {
              final ingredient = HiveService.ingredientBox.values.firstWhere(
                (i) => i.name == log.ingredientName
              );
              if (ingredient.category != _selectedCategory) return false;
            } catch (_) {
              return false; // Ingredient might have been deleted
            }
          }
          return true;
        }).toList();

        // Sort
        filteredLogs.sort((a, b) {
           return _sortOption == "Oldest First" 
             ? a.dateTime.compareTo(b.dateTime)
             : b.dateTime.compareTo(a.dateTime);
        });

        if (filteredLogs.isEmpty) return _buildEmptyState("No history logs found in this period");

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredLogs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = filteredLogs[index];
            final isPositive = log.changeAmount > 0;
            final color = isPositive ? ThemeConfig.primaryGreen : Colors.orange;
            
            // Compact, Clickable Card
            return Material(
              color: Colors.white,
              elevation: 0.5,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _showLogDetails(log),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Status Strip
                      Container(
                        width: 4, 
                        height: 30, 
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.ingredientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${log.action} • ${log.userName}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Values
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${isPositive ? '+' : ''}${log.changeAmount} ${log.unit}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                          ),
                          Text(
                            DateFormat('MMM dd, h:mm a').format(log.dateTime),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🛠 ADJUSTMENT SHEET (With Sync Fix)
  // ---------------------------------------------------------------------------
  void _showAdjustmentSheet(BuildContext context, IngredientModel ingredient) {
    final TextEditingController qtyController = TextEditingController();
    String action = "Restock"; 
    
    // Default to Main Unit (e.g., L)
    String selectedUnit = ingredient.unit; 
    bool isUsingBaseUnit = false; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Adjust ${ingredient.name}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // 1. ACTION
                  Row(
                    children: [
                      _buildChoiceChip("Restock", action == "Restock", (val) => setSheetState(() => action = "Restock")),
                      const SizedBox(width: 10),
                      _buildChoiceChip("Correction", action == "Correction", (val) => setSheetState(() => action = "Correction")),
                      const SizedBox(width: 10),
                      _buildChoiceChip("Waste", action == "Waste", (val) => setSheetState(() => action = "Waste")),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. UNIT SELECTOR (Only if different)
                  if (ingredient.unit != ingredient.baseUnit) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUnitToggle(
                              label: ingredient.unit, // Main Unit (e.g. "L")
                              isSelected: !isUsingBaseUnit,
                              onTap: () => setSheetState(() {
                                isUsingBaseUnit = false;
                                selectedUnit = ingredient.unit;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _buildUnitToggle(
                              label: ingredient.baseUnit, // Base Unit (e.g. "mL")
                              isSelected: isUsingBaseUnit,
                              onTap: () => setSheetState(() {
                                isUsingBaseUnit = true;
                                selectedUnit = ingredient.baseUnit;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. INPUT
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Quantity to ${action == 'Restock' ? 'Add' : 'Deduct'} ($selectedUnit)",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                        onPressed: () async {
                          final inputAmount = double.tryParse(qtyController.text);
                          if (inputAmount == null || inputAmount <= 0) return;

                          // Convert input to Base Units
                          double factor = isUsingBaseUnit ? 1.0 : ingredient.conversionFactor;
                          double changeInBaseUnits = inputAmount * factor;

                          double newQuantity = ingredient.quantity;
                          if (action == "Restock") {
                            newQuantity += changeInBaseUnits;
                          } else {
                            newQuantity -= changeInBaseUnits;
                          }

                          // 1. Update & Save Local
                          ingredient.quantity = newQuantity;
                          ingredient.updatedAt = DateTime.now();
                          await ingredient.save(); // Updates Hive

                          // 2. ✅ FIX: SYNC TO SUPABASE (QUEUE)
                          SupabaseSyncService.addToQueue(
                            table: 'ingredients',
                            action: 'UPSERT',
                            data: ingredient.toJson(),
                          );

                          // 3. Log the action (also syncs log)
                          await InventoryLogService.log(
                            ingredientName: ingredient.name,
                            action: action,
                            quantity: inputAmount, 
                            unit: selectedUnit,
                            reason: "Mobile Adjustment",
                          );

                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    // Show Current Stock in SELECTED Unit
                    "Current Stock: ${isUsingBaseUnit ? ingredient.quantity.toStringAsFixed(0) : ingredient.displayQuantity.toStringAsFixed(2)} $selectedUnit", 
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🛠 UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildUnitToggle({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: ThemeConfig.primaryGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      showCheckmark: false,
    );
  }

  void _showLogDetails(InventoryLogModel log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Log Details", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Text(log.ingredientName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThemeConfig.primaryGreen)),
              const Divider(height: 30),
              _buildDetailRow("Action", log.action),
              _buildDetailRow("Quantity", "${log.changeAmount > 0 ? '+' : ''}${log.changeAmount} ${log.unit}"),
              _buildDetailRow("Performed By", log.userName),
              _buildDetailRow("Date", DateFormat('MMM dd, yyyy').format(log.dateTime)),
              _buildDetailRow("Time", DateFormat('h:mm a').format(log.dateTime)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Reason / Note:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(log.reason, style: const TextStyle(fontSize: 14)),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: ThemeConfig.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}