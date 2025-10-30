import 'package:phone_site/provider/test_data.dart';
import 'dart:math';


Future<Map<String, Map<String, double>>> getMappedInventoryData() async {
  //await Future.delayed(const Duration(milliseconds: 300)); 

  Map<String, Map<String, double>> groupedData = {};

  for (var item in testInventoryItems) {
    final category = item['item_category'];
    final name = item['item_name'];
    final quantity = item['item_quantity'];

    // Normalize the "progress" value for visualization (0–1)
    double progress = _normalizeQuantity(category, quantity);

    groupedData.putIfAbsent(category, () => {});
    groupedData[category]![name] = progress;
  }

  return groupedData;
}

/// Simple normalization rule for mock visualization.
/// Later, this can be replaced by thresholds from DB or settings.
double _normalizeQuantity(String category, num quantity) {
  switch (category) {
    case 'Cups':
    case 'Lids':
    case 'Straws':
      return min(quantity / 100.0, 1.0); // assume 100 pcs is full
    case 'Syrups':
      return min(quantity / 750.0, 1.0); // 750ml = full
    default:
      return min(quantity / 1.0, 1.0); // 1kg or 1L = full
  }
}