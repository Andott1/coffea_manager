import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SortButton extends StatefulWidget {
  final Function(String) onSortSelected;

  const SortButton({super.key, required this.onSortSelected});

  @override
  State<SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<SortButton> {
  String? selectedOption;

  final List<String> sortOptions = [
    "A - Z",
    "Quantity (Low → High)",
    "Quantity (High → Low)",
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 4,
      onSelected: (value) {
        setState(() {
          selectedOption = value;
        });
        widget.onSortSelected(value);
      },
      itemBuilder: (context) => sortOptions
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(253, 255, 255, 255),
          border: Border.all(
            color: const Color.fromARGB(143, 0, 0, 0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, color: Colors.black, size: 18),
            const SizedBox(width: 5),
            Text(
              selectedOption ?? "Sort by",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
