import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStockDialog {
  static Future<void> showAddStockDialog({
    required BuildContext context,
    required Map<String, dynamic> stock,
    required VoidCallback onConfirm,
  }) async {
    double tempQty = stock['item_quantity'] * 1.0;
    final controller = TextEditingController(text: tempQty.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromARGB(143, 0, 0, 0),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _getCategoryImage(stock['item_category']),
                            height: 50,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            stock['item_category'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // 🧾 Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock['item_name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity (${stock['item_unit']})',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Quantity controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // - Button
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Color.fromRGBO(91, 57, 33, 1),
                                ),
                                onPressed: () {
                                  if (tempQty > 0) tempQty -= 20;
                                  controller.text = tempQty
                                      .toStringAsFixed(2)
                                      .replaceAll('.00', '');
                                },
                              ),

                              //  Quantity box
                              Container(
                                width: 70,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      160,
                                      160,
                                      160,
                                    ),
                                    width: 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: controller,
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  onChanged: (value) {
                                    tempQty = double.tryParse(value) ?? tempQty;
                                  },
                                ),
                              ),

                              // + Button
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color.fromRGBO(91, 57, 33, 1),
                                ),
                                onPressed: () {
                                  tempQty += 20;
                                  controller.text = tempQty
                                      .toStringAsFixed(2)
                                      .replaceAll('.00', '');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Cancel / Confirm Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            169,
                            207,
                            180,
                            28,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          stock['item_quantity'] =
                              int.tryParse(controller.text) ?? tempQty;
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getCategoryImage(String category) {
    switch (category) {
      case 'Coffee & Tea Base':
        return 'assets/coffee.png';
      case 'Dairy & Creamers':
        return 'assets/milk.png';
      case 'Syrups':
        return 'assets/syrup.png';
      case 'Sauces & Add-ons':
        return 'assets/sauce.png';
      case 'Cups':
        return 'assets/cup.png';
      case 'Lids':
        return 'assets/lids.png';
      case 'Straws':
        return 'assets/straws.png';
      default:
        return 'assets/logo2.png';
    }
  }
}
