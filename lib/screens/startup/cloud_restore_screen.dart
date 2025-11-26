import 'package:flutter/material.dart';
import '../../core/services/supabase_sync_service.dart';
import '../../core/services/logger_service.dart';
import 'startup_screen.dart';

class CloudRestoreScreen extends StatefulWidget {
  const CloudRestoreScreen({super.key});

  @override
  State<CloudRestoreScreen> createState() => _CloudRestoreScreenState();
}

class _CloudRestoreScreenState extends State<CloudRestoreScreen> {
  bool _isLoading = false;
  String _status = "Connect to Wi-Fi to start";

  Future<void> _startRestore() async {
    setState(() {
      _isLoading = true;
      _status = "Connecting to Supabase...";
    });

    try {
      // Pulls Users, Products, Ingredients, etc.
      await SupabaseSyncService.restoreFromCloud();
      
      if (mounted) {
        setState(() => _status = "✅ Sync Complete!");
        // Navigate to Login Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StartupScreen()),
        );
      }
    } catch (e) {
      LoggerService.error("Restore failed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = "❌ Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_download, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Welcome to Coffea Mobile",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.amber)
              else
                ElevatedButton.icon(
                  onPressed: _startRestore,
                  icon: const Icon(Icons.sync),
                  label: const Text("DOWNLOAD DATA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}