import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phone_site/screens/dashboard/widget/inventory_mapping.dart';

class SummaryContent extends StatefulWidget {
  const SummaryContent({super.key});

  @override
  State<SummaryContent> createState() => _SummaryContentState();
}

class _SummaryContentState extends State<SummaryContent> {
  late Future<Map<String, Map<String, double>>> summaryData;

  @override
  void initState() {
    super.initState();
    summaryData = getMappedInventoryData(); 
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: summaryData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No summary data available.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          );
        }

        final categories = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Title
              Text(
                'Summary',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),

              // mapped data
              Column(
                children: categories.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: _buildCategory(entry.key, entry.value),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategory(String title, Map<String, double> items) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(245, 245, 245, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Items within category
          Column(
            children: items.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildProgressBar(entry.key, entry.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Color bar logic
  Widget _buildProgressBar(String label, double progress) {
    Color barColor;
    if (progress < 0.3) {
      barColor = Colors.redAccent;
    } else if (progress < 0.6) {
      barColor = Colors.orangeAccent;
    } else {
      barColor = Colors.green;
    }

    return Row(
      children: [
        // Product name
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color.fromARGB(237, 0, 0, 0),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Progress bar
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: barColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
