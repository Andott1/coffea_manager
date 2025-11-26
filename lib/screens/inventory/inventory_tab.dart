import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/ingredient_model.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/inventory_log_service.dart';
import '../../core/services/session_user.dart'; 
import '../../config/theme_config.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search ingredients...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // 2. Ingredient List
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: HiveService.ingredientBox.listenable(),
            builder: (context, Box<IngredientModel> box, _) {
              // Filter Logic
              final ingredients = box.values.where((ing) {
                return ing.name.toLowerCase().contains(_searchQuery);
              }).toList();

              // Sort: Low stock first, then alphabetical
              ingredients.sort((a, b) {
                bool aLow = a.quantity <= a.reorderLevel;
                bool bLow = b.quantity <= b.reorderLevel;
                if (aLow && !bLow) return -1;
                if (!aLow && bLow) return 1;
                return a.name.compareTo(b.name);
              });

              if (ingredients.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty ? "No ingredients found." : "No matches.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB if needed
                itemCount: ingredients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ing = ingredients[index];
                  final isLowStock = ing.quantity <= ing.reorderLevel;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isLowStock ? Colors.red.shade100 : ThemeConfig.primaryGreen.withOpacity(0.1),
                      child: Icon(
                        Icons.kitchen, 
                        color: isLowStock ? Colors.red : ThemeConfig.primaryGreen,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      ing.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${ing.quantity.toStringAsFixed(1)} ${ing.baseUnit} available",
                      style: TextStyle(
                        color: isLowStock ? Colors.red : Colors.grey.shade700,
                        fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showAdjustmentSheet(context, ing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLowStock ? Colors.red : ThemeConfig.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text("Adjust"),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 3. The "Quick Action" Bottom Sheet
  void _showAdjustmentSheet(BuildContext context, IngredientModel ingredient) {
    final TextEditingController qtyController = TextEditingController();
    String action = "Restock"; // Default action
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow keyboard to push it up
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              
              // Action Toggle
              Row(
                children: [
                  _buildActionChip("Restock", action == "Restock", (val) {
                    action = "Restock";
                    (context as Element).markNeedsBuild(); // Rebuild for UI update
                  }),
                  const SizedBox(width: 10),
                  _buildActionChip("Correction", action == "Correction", (val) {
                    action = "Correction";
                    (context as Element).markNeedsBuild();
                  }),
                  const SizedBox(width: 10),
                  _buildActionChip("Waste", action == "Waste", (val) {
                    action = "Waste";
                    (context as Element).markNeedsBuild();
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Input
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Quantity (${ingredient.unit})",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    onPressed: () async {
                      final amount = double.tryParse(qtyController.text);
                      if (amount == null || amount <= 0) return;

                      // CALCULATE NEW QUANTITY
                      double newQuantity = ingredient.quantity;
                      if (action == "Restock") {
                        newQuantity += amount;
                      } else {
                        // Correction (subtract) or Waste (subtract)
                        newQuantity -= amount;
                      }

                      // UPDATE HIVE
                      ingredient.quantity = newQuantity;
                      ingredient.updatedAt = DateTime.now();
                      await ingredient.save();

                      // LOG THE CHANGE
                      // ✅ FIX: Using correct getter 'current'
                      final user = SessionUser.current?.fullName ?? "Mobile User";
                      
                      // ✅ FIX: Using correct method 'log'
                      await InventoryLogService.log(
                        ingredientName: ingredient.name,
                        action: action,
                        quantity: amount,
                        unit: ingredient.unit,
                        reason: "Mobile Adjustment",
                      );

                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Current Stock: ${ingredient.quantity.toStringAsFixed(2)} ${ingredient.unit}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionChip(String label, bool isSelected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: ThemeConfig.primaryGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}