import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../bloc/connectivity/connectivity_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../services/session_user.dart';
import '../services/supabase_sync_service.dart';
import '../../config/theme_config.dart';
import '../../screens/startup/startup_screen.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionUser.current;
    
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, isOnline) {
        return GestureDetector(
          onTap: () => _showManagerMenu(context, isOnline),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2), // Gap between border and image
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                // 🟢 RED/GREEN STATUS BORDER
                color: isOnline ? Colors.green : Colors.red, 
                width: 2.5, 
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: ThemeConfig.primaryGreen,
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showManagerMenu(BuildContext context, bool isOnline) {
    final user = SessionUser.current;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: ThemeConfig.primaryGreen,
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? "?",
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? "Guest",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.role.name.toUpperCase() ?? "STAFF",
                        style: const TextStyle(color: Colors.grey, letterSpacing: 1.0, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              
              // 2. Status Indicator
              ListTile(
                leading: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off, 
                  color: isOnline ? Colors.green : Colors.red
                ),
                title: Text(isOnline ? "System Online" : "System Offline"),
                subtitle: Text(isOnline ? "Ready to sync" : "Check your internet connection"),
              ),

              // 3. Actions
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.blue),
                title: const Text("Sync Data Now"),
                subtitle: const Text("Pull latest updates from cloud"),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  _runSync(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Log Out"),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const StartupScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 20),
              
              // 4. Footer
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  return Text(
                    "Coffea Manager v${snapshot.data?.version ?? '...'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runSync(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing Data...")));
    try {
      await SupabaseSyncService.restoreFromCloud();
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Sync Complete")));
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}