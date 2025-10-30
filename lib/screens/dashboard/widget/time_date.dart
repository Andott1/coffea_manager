import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TimeDateContent extends StatefulWidget {
  const TimeDateContent({super.key});

  @override
  State<TimeDateContent> createState() => TimeDateContentState();
}

class TimeDateContentState extends State<TimeDateContent> {
  String _time = '';
  String _month = '';
  String _day = '';
  String _dateNum = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _time = DateFormat('hh : mm a').format(now);
      _month = DateFormat('MMMM').format(now);
      _day = DateFormat('EEE').format(now);
      _dateNum = DateFormat('d').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(199, 174, 137, 1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color.fromARGB(255, 77, 57, 28), width: 1.5),
        ),
        child: Row(
          children: [

            // TIME
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _time,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 15),

            // DATE
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$_day, $_month",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(214, 0, 0, 0),
                    ),
                  ),
                  Text(
                    _dateNum,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 15, 15, 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
