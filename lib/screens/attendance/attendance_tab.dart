import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/hive_service.dart';
import '../../config/theme_config.dart';
import 'attendance_verification_sheet.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar for Filtering
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: ThemeConfig.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ThemeConfig.primaryGreen,
            tabs: const [
              Tab(text: "Pending Review"),
              Tab(text: "History"),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: HiveService.attendanceBox.listenable(),
            builder: (context, Box<AttendanceLogModel> box, _) {
              final allLogs = box.values.toList();
              
              // Sort newest first
              allLogs.sort((a, b) => b.timeIn.compareTo(a.timeIn));

              final pendingLogs = allLogs.where((l) => !l.isVerified).toList();
              final historyLogs = allLogs.where((l) => l.isVerified).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildLogList(pendingLogs, isPending: true),
                  _buildLogList(historyLogs, isPending: false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogList(List<AttendanceLogModel> logs, {required bool isPending}) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline : Icons.history, 
              size: 60, color: Colors.grey.shade300
            ),
            const SizedBox(height: 10),
            Text(
              isPending ? "No pending approvals" : "No attendance history",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        final user = HiveService.userBox.get(log.userId); // Fetch User details
        
        return Card(
          elevation: isPending ? 3 : 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              // Open Verification Sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AttendanceVerificationSheet(log: log, employee: user),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Photo Thumbnail
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: (log.proofImage != null && log.proofImage!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(log.proofImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (log.proofImage == null || log.proofImage!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? "Unknown ID: ${log.userId}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          DateFormat('MMM dd • h:mm a').format(log.timeIn),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (!isPending && log.rejectionReason != null)
                          Text(
                            "Rejected: ${log.rejectionReason}",
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  // Status Icon
                  if (isPending)
                    const Icon(Icons.chevron_right, color: Colors.grey)
                  else
                    Icon(
                      log.rejectionReason == null ? Icons.check_circle : Icons.cancel,
                      color: log.rejectionReason == null ? Colors.green : Colors.red,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}